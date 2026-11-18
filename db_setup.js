/**
 * محرك الربط مع قاعدة بيانات SQLite السحابية (Turso / LibSQL) ومحلياً
 * Smart Travel Agency Platform - SQLite Database Manager
 */

const fs = require('fs');
const path = require('path');

// إعدادات الاتصال بقاعدة بيانات SQLite أو Turso Cloud
const DB_CONFIG = {
    // محلياً: مسار ملف sqlite
    localDatabasePath: path.join(__dirname, 'travel_agency.sqlite'),
    
    // سحابياً عبر Turso:
    // للحصول على الرابط المجاني: turso db create travel-db -> يعطيك libsql://travel-db-[username].turso.io
    tursoUrl: process.env.TURSO_DATABASE_URL || 'libsql://travel-agency-free.turso.io',
    tursoAuthToken: process.env.TURSO_AUTH_TOKEN || '',
    mode: process.env.TURSO_AUTH_TOKEN ? 'turso_cloud' : 'local_sqlite'
};

console.log('====================================================');
console.log('✈️ نظام قاعدة بيانات وكالة السفر الرقمية الذكية');
console.log(`وضع التشغيل: ${DB_CONFIG.mode}`);
console.log('====================================================');

function printSchemaSummary() {
    const schemaFile = path.join(__dirname, 'schema.sql');
    if (fs.existsSync(schemaFile)) {
        console.log('✅ تم العثور على ملف المخطط (schema.sql)');
        console.log('الجداول المعرفة:');
        console.log('  1. users (المدير العام + 10 موظفين + العملاء)');
        console.log('  2. services (الطيران، البواخر، التأشيرات، البصات)');
        console.log('  3. bookings (سجلات الحجوزات، المبالغ، والمسافرين)');
        console.log('  4. documents (مستندات KYC، الجوازات، البطاقات)');
        console.log('  5. chat_messages (رسائل الدردشة الحية والمرفقات)');
        console.log('  6. invoices_tickets (التذاكر الصادرة والفواتير PDF)');
    }
}

printSchemaSummary();

module.exports = {
    DB_CONFIG
};
