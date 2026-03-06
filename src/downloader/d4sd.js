const { spawn } = require('child_process');
const path = require('path');
const prompts = require('prompts');

const D4SD_CLI = path.resolve(__dirname, '..', '..', 'd4sd', 'esm', 'cli.js');

// Shelves that support listing all books (getItems() is implemented)
const supportsListing = new Set(['digi', 'trauner']);

module.exports = async function d4sd(shelf, email, passwd) {
    let books = [];
    let downloadAll = false;

    if (supportsListing.has(shelf)) {
        const { all } = await prompts({
            type: 'confirm',
            name: 'all',
            message: 'Download all books from the shelf?',
            initial: true,
        });
        downloadAll = !!all;
    }

    if (!downloadAll) {
        const { bookInput } = await prompts({
            type: 'text',
            name: 'bookInput',
            message: supportsListing.has(shelf)
                ? 'Book titles or URLs (comma-separated, supports glob patterns like "Math*"):'
                : 'Book URLs (comma-separated):',
        });
        books = (bookInput || '').split(',').map(s => s.trim()).filter(Boolean);
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
