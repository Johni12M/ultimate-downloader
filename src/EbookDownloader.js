#!/usr/bin/env node

// Batch stdout writes within each microtask tick to eliminate terminal flickering.
// prompts calls stdout.write() many times per render; Windows redraws after each one.
// By flushing everything in a single write(), only one redraw happens per render cycle.
(function patchStdoutForFlicker() {
    const orig = process.stdout.write.bind(process.stdout);
    let pending = null;
    process.stdout.write = function(data, enc, cb) {
        const s = Buffer.isBuffer(data) ? data.toString(enc || 'utf8') : String(data);
        if (pending === null) {
            pending = s;
            queueMicrotask(() => { const out = pending; pending = null; orig(out); });
        } else {
            pending += s;
        }
        if (typeof enc === 'function') enc();
        else if (typeof cb === 'function') cb();
        return true;
    };
})();

// Force Unicode symbols in prompts library (fixes Windows ASCII fallback)
try {
    const figures = require('prompts/lib/util/figures');
    figures.radioOn      = '◎';
    figures.radioOff     = '○';
    figures.tick         = '✓';
    figures.cross        = '✖';
    figures.pointer      = '❯';
    figures.pointerSmall = '›';
    figures.ellipsis     = '…';
} catch(e) {}

const readline = require('readline');
const axios = require('axios');
const qs = require('querystring');
const axiosCookieJarSupport = require('axios-cookiejar-support').wrapper;
const tough = require('tough-cookie');
const fs = require('fs');
const PDFDoc = require('pdfkit');
const util = require('util')
const prompts = require('prompts');
const https = require('https')
const crypto = require('crypto')
var spawn = require('child_process').spawn
const sizeOf = require('image-size')
const pdflib = require("pdf-lib")

var HTMLParser = require('node-html-parser');
var parseString = require('xml2js').parseString;
const { stdin, stdout } = require('process');
const { resolve } = require('path');
const path = require('path');
const { url } = require('inspector');
const transformationMatrix = require('transformation-matrix')
const AdmZip  = require('adm-zip')
const consumers = require('node:stream/consumers')
const { PassThrough } = require('stream')

axiosCookieJarSupport(axios);

const cornelsen = require('./downloader/cornelsen')
const kiosquemag = require('./downloader/kiosquemag')
const book2look = require('./downloader/book2look')
const allango = require('./downloader/allango')
const clicknstudy = require('./downloader/clicknstudy')
const clicknteach = require('./downloader/clicknteach')
const klett = require('./downloader/klett')
const westermann = require('./downloader/westermann')
const scook = require('./downloader/scook')
const cornelsench = require('./downloader/cornelsench')
const helbling = require('./downloader/helbling')
const d4sd = require('./downloader/d4sd')

const useLegacy = process.argv.includes('--legacy')
const D4SD_PUBLISHERS = ['digi', 'scook-d4sd', 'trauner', 'helbling-d4sd']

// ── Auto-update check ─────────────────────────────────────────────────────────
async function checkForUpdate() {
    try {
        const pkgPath = path.resolve(__dirname, '..', 'package.json');
        const currentVersion = JSON.parse(fs.readFileSync(pkgPath, 'utf8')).version;
        const res = await axios.get(
            'https://api.github.com/repos/Johni12M/ultimate-downloader/releases/latest',
            { timeout: 5000, headers: { 'User-Agent': 'ultimate-downloader' } }
        );
        const latestTag = res.data.tag_name.replace(/^v/, '');
        if (latestTag === currentVersion) return;

        console.log(`\n  A new version is available: v${latestTag} (you have v${currentVersion})`);
        const { doUpdate } = await prompts({
            type: 'confirm',
            name: 'doUpdate',
            message: `Update to v${latestTag} now?`,
            initial: true
        });
        if (!doUpdate) { console.log(''); return; }

        const assets = res.data.assets || [];
        if (process.platform === 'win32') {
            const exeAsset = assets.find(a => a.name.endsWith('.exe'));
            if (!exeAsset) { console.log('No installer found in release assets.'); return; }
            const dest = path.join(require('os').tmpdir(), exeAsset.name);
            console.log(`Downloading ${exeAsset.name}...`);
            const writer = require('fs').createWriteStream(dest);
            const dl = await axios.get(exeAsset.browser_download_url, { responseType: 'stream', timeout: 120000 });
            await new Promise((res, rej) => { dl.data.pipe(writer); writer.on('finish', res); writer.on('error', rej); });
            console.log('Launching installer...');
            require('child_process').spawn(dest, [], { detached: true, stdio: 'ignore' }).unref();
            process.exit(0);
        } else {
            const shAsset = assets.find(a => a.name === 'install.sh');
            if (!shAsset) { console.log('No install.sh found in release assets.'); return; }
            console.log('Running install.sh...\n');
            require('child_process').spawnSync('bash', ['-c', `curl -fsSL "${shAsset.browser_download_url}" | bash`], { stdio: 'inherit' });
            process.exit(0);
        }
    } catch (e) {
        // Silently skip if offline or API unavailable
    }
}

async function main() {
    await checkForUpdate();
    prompts([
        {
        type: 'select',
        name: 'publisher',
        message: "Publisher / Website",
        choices: [
            // --- digi4school-based (d4sd) ---
            {
                title: 'Digi4School (digi4school.at)',
                value: "digi"
            },
            {
                title: 'Scook (scook.at)',
                value: "scook-d4sd"
            },
            {
                title: 'Trauner DigiBox',
                value: "trauner"
            },
            {
                title: 'Helbling e-zone',
                value: "helbling-d4sd"
            },
            // --- other publishers ---
            {
                title: 'Cornelsen',
                value: "cornelsen"
            },
            {
                title: 'Klett',
                value: "klett"
            },
            {
                title: 'Klett allango',
                value: "allango"
            },
            {
                title: 'Westermann',
                value: "westermann"
            },
            {
                title: 'C.C.BUCHNER - click & study',
                value: "clicknstudy"
            },
            {
                title: 'C.C.BUCHNER - click & teach',
                value: "clicknteach"
            },
            {
                title: 'book2look.com',
                value: "book2look"
            },
            {
                title: 'Cornelsen.ch',
                value: "cornelsench"
            },
            {
                title: "kiosquemag.com",
                value: "kiosquemag"
            },
            // --- legacy (only shown with --legacy flag) ---
            ...(useLegacy ? [
                {
                    title: 'scook (Cornelsen) - legacy',
                    value: "scook"
                },
                {
                    title: 'Helbling Media App - legacy',
                    value: 'helbling'
                }
            ] : [])
        ]
    },
    {
        type: (prev, values) => values.publisher == "book2look" ? null : 'text',
        name: 'email',
        message: (prev, values) => values.publisher == "cornelsen" ? "Name" : 'Email'
    },
    {
        type: (prev, values) => values.publisher == 'book2look' ? null : 'password',
        name: 'passwd',
        message: "Password",
    },
    {
        type: (prev, values) => D4SD_PUBLISHERS.includes(values.publisher) ? null : 'confirm',
        name: 'deleteAllOldTempImages',
        message: "Overwrite old temp files",
        initial: true
    }
]).then(inputs => {
    try {
        const config = JSON.parse(fs.readFileSync("./config.json", "utf-8") ?? "{}")
        inputs.email = inputs.email || config?.[inputs.publisher]?.email;
        inputs.passwd = inputs.passwd || config?.[inputs.publisher]?.passwd;
    } catch(ex) {}

    switch (inputs.publisher) {
        case "digi":
        case "scook-d4sd":
        case "trauner":
        case "helbling-d4sd": {
            const shelfId = { 'scook-d4sd': 'scook', 'helbling-d4sd': 'helbling' }[inputs.publisher] ?? inputs.publisher;
            d4sd(shelfId, inputs.email, inputs.passwd)
            break;
        }
        case "cornelsen":
            cornelsen(inputs.email, inputs.passwd, inputs.deleteAllOldTempImages, false)
            break;
        case "klett":
            klett(inputs.email, inputs.passwd, inputs.deleteAllOldTempImages)
            break;
        case "allango":
            allango(inputs.email, inputs.passwd, inputs.deleteAllOldTempImages)
            break;
        case "scook":
            scook(inputs.email, inputs.passwd, inputs.deleteAllOldTempImages)
            break;
        case "westermann":
            westermann(inputs.email, inputs.passwd, inputs.deleteAllOldTempImages)
            break;
        case "clicknstudy":
            clicknstudy(inputs.email, inputs.passwd, inputs.deleteAllOldTempImages)
            break;
        case "clicknteach":
            clicknteach(inputs.email, inputs.passwd, inputs.deleteAllOldTempImages)
            break;
        case "kiosquemag":
            kiosquemag(inputs.email, inputs.passwd, inputs.deleteAllOldTempImages)
            break;
        case "cornelsench":
            cornelsench(inputs.email, inputs.passwd, inputs.deleteAllOldTempImages, true)
            break;
        case 'book2look':
            book2look(inputs.deleteAllOldTempImages)
            break;
        case 'helbling':
            helbling(inputs.email, inputs.passwd, inputs.deleteAllOldTempImages)
            break;
    }
})
}

main();
