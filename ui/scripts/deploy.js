/**
 * Deployment script for BDC Bridge UI
 * 
 * This script copies the built UI files to the server's static directory
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const SOURCE_DIR = path.resolve(__dirname, '../build');
const SERVER_STATIC_DIR = path.resolve(__dirname, '../../server/static');

console.log('Starting UI deployment...');

// 1. Ensure server static directory exists
if (!fs.existsSync(SERVER_STATIC_DIR)) {
  console.log(`Creating static directory: ${SERVER_STATIC_DIR}`);
  fs.mkdirSync(SERVER_STATIC_DIR, { recursive: true });
}

// 2. Clean existing files
console.log('Cleaning existing files...');
try {
  fs.readdirSync(SERVER_STATIC_DIR).forEach(file => {
    const filePath = path.join(SERVER_STATIC_DIR, file);
    if (fs.lstatSync(filePath).isDirectory()) {
      fs.rmSync(filePath, { recursive: true, force: true });
    } else {
      fs.unlinkSync(filePath);
    }
  });
} catch (err) {
  console.error('Error cleaning directory:', err);
}

// 3. Copy new build
console.log(`Copying files from ${SOURCE_DIR} to ${SERVER_STATIC_DIR}`);
try {
  execSync(`cp -R ${SOURCE_DIR}/* ${SERVER_STATIC_DIR}/`);
  console.log('Files copied successfully!');
} catch (err) {
  console.error('Error copying files:', err);
  process.exit(1);
}

console.log('UI deployment complete!'); 