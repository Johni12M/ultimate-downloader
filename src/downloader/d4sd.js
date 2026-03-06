const { spawn, spawnSync } = require('child_process');
const path = require('path');
const prompts = require('prompts');

const D4SD_CLI = path.resolve(__dirname, '..', '..', 'd4sd', 'esm', 'cli.js');

// Shelves that support listing all books (getItems() is implemented)
const supportsListing = new Set(['digi', 'trauner']);

function fetchBookList(shelf, email, passwd, timeout) {
    return new Promise((resolve) => {
        const args = [D4SD_CLI, '-s', shelf, '-u', email, '-p', passwd, '--list'];
        const child = spawn('node', args, { stdio: ['ignore', 'pipe', 'pipe'] });
        let stdout = '';
        child.stdout.on('data', (d) => (stdout += d.toString()));
        const timer = setTimeout(() => { child.kill(); resolve([]); }, timeout || 60000);
        child.on('close', () => {
            clearTimeout(timer);
            const titles = stdout
                .split('\n')
                .map((l) => l.trim())
                .filter((l) => l.length > 0 && !l.startsWith('[') && !l.startsWith('Error'));
            resolve(titles);
        });
        child.on('error', () => { clearTimeout(timer); resolve([]); });
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

        if (mode === 'all') {
            downloadAll = true;
        } else if (mode === 'select') {
            console.log('Fetching book list (logging in, please wait)...');
            const titles = await fetchBookList(shelf, email, passwd, 120000);
            if (titles.length === 0) {
                console.log('Could not fetch book list. Falling back to manual entry.');
            } else {
                const { selected } = await prompts({
                    type: 'multiselect',
                    name: 'selected',
                    message: `Select books to download (space to toggle, enter to confirm):`,
                    choices: titles.map((t) => ({ title: t, value: t })),
                    min: 1,
                });
                books = selected || [];
            }
        }

        if (!downloadAll && books.length === 0) {
            const { bookInput } = await prompts({
                type: 'text',
                name: 'bookInput',
                message: 'Book titles or URLs (comma-separated, supports glob patterns like "Math*"):',
            });
            books = (bookInput || '').split(',').map((s) => s.trim()).filter(Boolean);
        }
    } else {
        const { bookInput } = await prompts({
            type: 'text',
            name: 'bookInput',
            message: 'Book URLs (comma-separated):',
        });
        books = (bookInput || '').split(',').map((s) => s.trim()).filter(Boolean);
    }

    const { outDir } = await prompts({
        type: 'text',
        name: 'outDir',
        message: 'Output directory:',
        initial: './download',
    });

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

    const child = spawn('node', args, { stdio: 'inherit' });
    await new Promise((resolve, reject) => {
        child.on('close', resolve);
        child.on('error', reject);
    });
};
