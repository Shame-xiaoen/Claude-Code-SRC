import { readFileSync, writeFileSync } from "fs";
import sharp from "sharp";

const SIZES = [256, 128, 64, 48, 32, 16];

// Claude Code official SVG from @lobehub/icons
const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <rect x="0" y="0" width="24" height="24" rx="4" ry="4" fill="#09090B"/>
  <path fill="#D97757" fill-rule="evenodd" clip-rule="evenodd"
    d="M20.998 10.949H24v3.102h-3v3.028h-1.487V20H18v-2.921h-1.487V20H15v-2.921H9V20H7.488v-2.921H6V20H4.487v-2.921H3V14.05H0V10.95h3V5h17.998v5.949zM6 10.949h1.488V8.102H6v2.847zm10.51 0H18V8.102h-1.49v2.847z"/>
</svg>`;

async function main() {
  const pngs: Buffer[] = [];
  for (const size of SIZES) {
    const png = await sharp(Buffer.from(svg)).resize(size, size).png().toBuffer();
    pngs.push(png);
  }

  const headerSize = 6;
  const entrySize = 16;
  const totalHeader = headerSize + entrySize * pngs.length;
  let offset = totalHeader;
  const dataSize = pngs.reduce((a, d) => a + d.length, 0);
  const buf = Buffer.alloc(totalHeader + dataSize);

  let pos = 0;
  buf.writeUInt16LE(0, pos); pos += 2;  // reserved
  buf.writeUInt16LE(1, pos); pos += 2;  // type: icon
  buf.writeUInt16LE(pngs.length, pos); pos += 2;  // count

  for (let i = 0; i < pngs.length; i++) {
    const s = SIZES[i];
    const data = pngs[i];
    const w = s >= 256 ? 0 : s;
    buf.writeUInt8(w, pos);
    buf.writeUInt8(w, pos + 1);
    buf.writeUInt8(0, pos + 2);
    buf.writeUInt8(0, pos + 3);
    buf.writeUInt16LE(0, pos + 4);
    buf.writeUInt16LE(32, pos + 6);
    buf.writeUInt32LE(data.length, pos + 8);
    buf.writeUInt32LE(offset, pos + 12);
    pos += 16;
    offset += data.length;
  }

  for (const data of pngs) {
    data.copy(buf, pos);
    pos += data.length;
  }

  writeFileSync("claude-code.ico", buf);
  console.log(`Generated claude-code.ico (${buf.length} bytes)`);
}

main().catch(console.error);
