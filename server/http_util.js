function corsHeaders() {
  return {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers': 'content-type, x-admin-push-secret',
  };
}

function sendJson(res, statusCode, body) {
  const payload = JSON.stringify(body);
  res.writeHead(statusCode, {
    ...corsHeaders(),
    'content-type': 'application/json',
    'content-length': Buffer.byteLength(payload),
  });
  res.end(payload);
}

function sendHtml(res, statusCode, html) {
  res.writeHead(statusCode, {
    ...corsHeaders(),
    'content-type': 'text/html; charset=utf-8',
    'content-length': Buffer.byteLength(html),
  });
  res.end(html);
}

function sendCsv(res, statusCode, csv, filename) {
  const safeName = String(filename || 'export.csv').replace(/[^\w.\-]+/g, '_');
  res.writeHead(statusCode, {
    ...corsHeaders(),
    'content-type': 'text/csv; charset=utf-8',
    'content-disposition': `attachment; filename="${safeName}"`,
    'content-length': Buffer.byteLength(csv),
  });
  res.end(csv);
}

function readJsonBody(req, { limitBytes = 64 * 1024 } = {}) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > limitBytes) {
        reject(new Error('body_too_large'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => {
      try {
        const raw = Buffer.concat(chunks).toString('utf8');
        if (!raw.trim()) {
          resolve({});
          return;
        }
        resolve(JSON.parse(raw));
      } catch (error) {
        reject(error);
      }
    });
    req.on('error', reject);
  });
}

module.exports = { sendJson, sendHtml, sendCsv, readJsonBody, corsHeaders };
