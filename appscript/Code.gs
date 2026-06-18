/**
 * Robi SMS Logger - Apps Script backend
 *
 * এই function টা Flutter app থেকে আসা POST request রিসিভ করে
 * active sheet এর একটা নতুন row এ (date, sender, content) যুক্ত করবে।
 *
 * Setup এর জন্য README.md দেখো।
 */

function doPost(e) {
  try {
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    var data = JSON.parse(e.postData.contents);

    sheet.appendRow([
      data.date || '',
      data.sender || '',
      data.content || ''
    ]);

    return ContentService
      .createTextOutput(JSON.stringify({ status: 'success' }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ status: 'error', message: err.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

// browser এ গিয়ে URL টা সরাসরি খুললে এই function চলবে, deploy ঠিকভাবে হয়েছে কিনা
// সেটা test করার জন্য সুবিধা হবে।
function doGet(e) {
  return ContentService
    .createTextOutput('Robi SMS Logger script চালু আছে ✅')
    .setMimeType(ContentService.MimeType.TEXT);
}
