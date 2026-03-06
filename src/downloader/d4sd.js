const { spawn } = require('child_process');
const path = require('path');
const prompts = require('prompts');

const __realdir = path.dirname(require('fs').realpathSync.native(__filename));
const D4SD_CLI = path.resolve(__realdir, '..', '..', 'd4sd', 'esm', 'cli.js');
const NODE = process.execPath; // use the same node binary that's running this script

// Shelves that support listing all books (getItems() is implemented)
const supportsListing = new Set(['digi', 'trauner']);

// Handle Ctrl+C: prompts returns {} with undefined values when cancelled
function cancelled(val) {
    return val === undefined;
}

function fetchBookList(shelf, email, passwd, timeout) {
    return new Promise((resolve) => {
        const args = [D4SD_CLI, '-s', shelf, '-u', email, '-p', passwd, '--list'];
        const child = spawn(NODE, args, { stdio: ['ignore', 'pipe', 'inherit'] });
        let stdout = '';
        child.stdout.on('data', (d) => (stdout += d.toString()));
        const timer = setTimeout(() => {
            child.kill();
            console.error('\nBook list fetch timed out after ' + Math.round(timeout / 1000) + 's.');
            resolve([]);
        }, timeout || 180000);
        child.on('close', () => {
            clearTimeout(timer);
            const lines = stdout.split('\n').map((l) => l.trim()).filter(Boolean);
            const errorLines = lines.filter((l) => l.startsWith('Error') || l.startsWith('['));
            const titles = lines.filter((l) => !l.startsWith('Error') && !l.startsWith('['));
            if (titles.length === 0 && errorLines.length > 0) {
                console.error('d4sd reported: ' + errorLines.join(' | '));
            }
            resolve(titles);
        });
        child.on('error', (e) => {
            clearTimeout(timer);
            console.error('Failed to start d4sd: ' + e.message);
            resolve([]);
        });
    });
}

module.exports = async function d4sd(shelf, email, passwd) {
    let books = [];
    let downloadAll = false;

    if (supportsListing.has(shelf)) {
        const { mode } = await prompts({
            type: 'select',
            name: 'mode',
            message: 'What do you want to do?',
            choices: [
                { title: 'Browse & select books from shelf', value: 'select' },
                { title: 'Download all books', value: 'all' },
                { title: 'Enter book titles / URLs manually', value: 'manual' },
            ],
        });
        if (cancelled(mode)) return;

        if (mode === 'all') {
            downloadAll = true;
        } else if (mode === 'select') {
            console.log('Fetching book list (logging in, please wait up to 3 minutes)...');
            const titles = await fetchBookList(shelf, email, passwd, 180000);
            if (titles.length === 0) {
                console.log('Could not fetch book list — falling back to manual entry.');
            } else {
                const { selected } = await prompts({
                    type: 'multiselect',
                    name: 'selected',
                    message: 'Select books to download (space to toggle, enter to confirm):',
                    choices: titles.map((t) => ({ title: t, value: t })),
                    min: 1,
                });
                if (cancelled(selected)) return;
                books = selected || [];
            }
        }

        if (!downloadAll && books.length === 0) {
            const { bookInput } = await prompts({
                type: 'text',
                name: 'bookInput',
                message: 'Book titles or URLs (comma-separated, supports glob patterns like "Math*"):',
            });
            if (cancelled(bookInput)) return;
            books = (bookInput || '').split(',').map((s) => s.trim()).filter(Boolean);
        }
    } else {
        const { bookInput } = await prompts({
            type: 'text',
            name: 'bookInput',
            message: 'Book URLs (comma-separated):',
        });
        if (cancelled(bookInput)) return;
        books = (bookInput || '').split(',').map((s) => s.trim()).filter(Boolean);
    }

    const { outDir } = await prompts({
        type: 'text',
        name: 'outDir',
        message: 'Output directory:',
        initial: './download',
    });
    if (cancelled(outDir)) return;

    const args = [
        D4SD_CLI,
        '-s', shelf,
        '-u', email,
        '-p', passwd,
        '-o', outDir || './download',
    ];

    if (downloadAll) {
        args.push('--all');
    } else {
        args.push(...books);
    }

    const child = spawn(NODE, args, { stdio: 'inherit' });
    await new Promise((resolve, reject) => {
        child.on('close', resolve);
        child.on('error', reject);
    });
};



