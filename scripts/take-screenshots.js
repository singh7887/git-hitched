const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const INVITE_CODE = process.env.INVITE_CODE || 'SOLSTICE';
const OUTPUT_DIR = path.join(__dirname, '..', 'docs', 'screenshots');
const VIEWPORT = { width: 1280, height: 800 };

const PAGES = [
  { name: 'home', path: '/', description: 'Home page (after auth)' },
  { name: 'events', path: '/events', description: 'Weekend events' },
  { name: 'travel', path: '/travel', description: 'Travel information' },
  { name: 'stay', path: '/stay', description: 'Accommodations' },
  { name: 'explore', path: '/explore', description: 'Things to do' },
  { name: 'attire', path: '/attire', description: 'Dress code' },
  { name: 'faq', path: '/faq', description: 'FAQ' },
  { name: 'rsvp', path: '/rsvp', description: 'RSVP lookup' },
];

async function run() {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });

  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  await page.setViewport(VIEWPORT);

  // Step 1: Screenshot the gate page (before auth)
  console.log('Capturing gate page...');
  await page.goto(`${BASE_URL}/`, { waitUntil: 'networkidle2' });
  await page.screenshot({ path: path.join(OUTPUT_DIR, 'gate.png'), fullPage: false });
  console.log('  saved gate.png');

  // Step 2: Authenticate with invite code
  console.log(`Entering invite code: ${INVITE_CODE}`);
  await page.type('input[placeholder="Invite code"]', INVITE_CODE);
  await page.click('input[type="submit"], button[type="submit"]');
  await page.waitForNavigation({ waitUntil: 'networkidle2' });

  // Step 2b: Enable all pages via dev toggle (POST /dev/toggle_pages)
  console.log('Enabling all pages via dev toggle...');
  const cookies = await page.cookies();
  await page.evaluate(async () => {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
    await fetch('/dev/toggle_pages', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      credentials: 'same-origin',
    });
  });
  console.log('  all pages enabled');

  // Step 3: Screenshot each page
  for (const { name, path: pagePath, description } of PAGES) {
    console.log(`Capturing ${description} (${pagePath})...`);
    await page.goto(`${BASE_URL}${pagePath}`, { waitUntil: 'networkidle2' });
    // Extra delay for images/fonts to load
    await new Promise(r => setTimeout(r, 1000));
    await page.screenshot({ path: path.join(OUTPUT_DIR, `${name}.png`), fullPage: false });
    console.log(`  saved ${name}.png`);
  }

  await browser.close();
  console.log(`\nDone! ${PAGES.length + 1} screenshots saved to ${OUTPUT_DIR}`);
}

run().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
