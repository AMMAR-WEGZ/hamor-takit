-- ========================================================
-- قاعدة بيانات وكالة هامور للسفر والسياحة (Hamoor Travel Platform)
-- متوافقة مع SQLite محلياً وسحابياً عبر Turso / LibSQL
-- العملة الرسمية: الجنيه السوداني (SDG)
-- ========================================================

PRAGMA foreign_keys = ON;

-- 1. جدول المستخدمين (Users Table)
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    password_hash TEXT NOT NULL,
    role TEXT CHECK(role IN ('admin', 'employee', 'customer')) NOT NULL DEFAULT 'customer',
    employee_title TEXT, -- للموظفين فقط: مشرف حجوزات، إلخ.
    avatar_url TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. جدول الخدمات (Services Table)
CREATE TABLE IF NOT EXISTS services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    service_code TEXT UNIQUE NOT NULL, -- flight, cruise, visa, bus
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    description TEXT,
    icon_name TEXT
);

-- 3. جدول الحجوزات (Bookings Table)
CREATE TABLE IF NOT EXISTS bookings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    booking_reference TEXT UNIQUE NOT NULL,
    customer_id INTEGER NOT NULL,
    assigned_employee_id INTEGER,
    service_code TEXT NOT NULL,
    service_provider TEXT, -- Tarco Aviation, Badr Airlines, etc.
    origin TEXT,
    destination TEXT,
    departure_date DATE,
    return_date DATE,
    passengers_count INTEGER DEFAULT 1,
    passenger_names TEXT,
    total_amount REAL DEFAULT 0.0,
    currency TEXT DEFAULT 'SDG', -- الجنيه السوداني
    status TEXT CHECK(status IN ('new', 'in_review', 'awaiting_payment', 'confirmed', 'ticket_issued', 'cancelled')) DEFAULT 'new',
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_employee_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (service_code) REFERENCES services(service_code)
);

-- 4. جدول المستندات والوثائق الثبوتية (Customer Documents / KYC)
CREATE TABLE IF NOT EXISTS documents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    booking_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    doc_type TEXT CHECK(doc_type IN ('passport', 'national_id', 'visa_photo', 'medical_report', 'other')) NOT NULL,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size_bytes INTEGER,
    mime_type TEXT,
    verified_status TEXT CHECK(verified_status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    verified_by_employee_id INTEGER,
    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by_employee_id) REFERENCES users(id)
);

-- 5. جدول رسائل المحادثة الحية (Live Chat Messages)
CREATE TABLE IF NOT EXISTS chat_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    booking_id INTEGER NOT NULL,
    sender_id INTEGER NOT NULL,
    sender_type TEXT CHECK(sender_type IN ('customer', 'employee', 'system')) NOT NULL,
    message_text TEXT NOT NULL,
    attachment_url TEXT,
    attachment_type TEXT,
    is_read INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 6. جدول الفواتير والتذاكر الرسمية (Invoices & Issued Tickets)
CREATE TABLE IF NOT EXISTS invoices_tickets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    booking_id INTEGER NOT NULL,
    item_type TEXT CHECK(item_type IN ('ticket', 'invoice', 'voucher')) NOT NULL,
    document_number TEXT UNIQUE NOT NULL,
    amount REAL DEFAULT 0.0,
    currency TEXT DEFAULT 'SDG',
    pdf_file_url TEXT NOT NULL,
    issued_by_employee_id INTEGER NOT NULL,
    issued_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (issued_by_employee_id) REFERENCES users(id)
);

-- البيانات الأولية والتجريبية (Seed Data)
INSERT OR IGNORE INTO services (service_code, name_ar, name_en, description, icon_name) VALUES
('flight', 'حجوزات الطيران', 'Flight Bookings', 'حجوزات طيران تاركو وبدر والخطوط العالمية', 'plane'),
('cruise', 'حجوزات البواخر البحرية', 'Sea Cruises & Ferries', 'رحلات بحرية وموانئ سواكن وجدة', 'ship'),
('visa', 'خدمات التأشيرات', 'Visa Services', 'تأشيرات سياحية، تجارية، وزيارات', 'id-card'),
('bus', 'بصات النقل البري', 'Bus Travel', 'رحلات برية بين الولايات والمحطات الرئيسية', 'bus');

-- إدخال المدير الرئيسي
INSERT OR IGNORE INTO users (id, full_name, email, phone, password_hash, role, employee_title) VALUES
(1, 'المدير العام', 'admin@smarttravel.com', '+249912300000', 'hash_admin_123', 'admin', 'مدير عام المنصة');

-- إدخال 10 موظفين بصلاحيات متنوعة
INSERT OR IGNORE INTO users (id, full_name, email, phone, password_hash, role, employee_title) VALUES
(2, 'محمد أحمد عثمان', 'm.ahmed@smarttravel.com', '+249912300001', 'hash_emp_1', 'employee', 'مشرف حجوزات طيران تاركو وبدر'),
(3, 'سارة إبراهيم علي', 's.ibrahim@smarttravel.com', '+249912300002', 'hash_emp_2', 'employee', 'مسؤولة حجوزات الطيران والـ GDS'),
(4, 'خالد عبد الله حسن', 'k.abdallah@smarttravel.com', '+249912300003', 'hash_emp_3', 'employee', 'مسؤول حجوزات البواخر البحرية'),
(5, 'فاطمة عمر محمد', 'f.omer@smarttravel.com', '+249912300004', 'hash_emp_4', 'employee', 'أخصائية استخراج وتدقيق التأشيرات'),
(6, 'طارق يوسف محمود', 't.youssef@smarttravel.com', '+249912300005', 'hash_emp_5', 'employee', 'مشرف خطوط النقل البري والبصات'),
(7, 'رنا صلاح الدين', 'r.salah@smarttravel.com', '+249912300006', 'hash_emp_6', 'employee', 'خدمة عملاء ومتابعة الحجوزات'),
(8, 'عمر كمال الطيب', 'o.kamal@smarttravel.com', '+249912300007', 'hash_emp_7', 'employee', 'مسؤول تدقيق المستندات والـ KYC'),
(9, 'منى عبد الرحمن', 'm.abdelrahman@smarttravel.com', '+249912300008', 'hash_emp_8', 'employee', 'مسؤولة المدفوعات وإصدار الفواتير'),
(10, 'حسام بشير النور', 'h.bashir@smarttravel.com', '+249912300009', 'hash_emp_9', 'employee', 'دعم فني وحجوزات طيران مسائية'),
(11, 'أميرة حسن إدريس', 'a.hassan@smarttravel.com', '+249912300010', 'hash_emp_10', 'employee', 'منسقة تأشيرات ورحلات دولية');

-- إدخال عملاء تجريبيين
INSERT OR IGNORE INTO users (id, full_name, email, phone, password_hash, role) VALUES
(12, 'عبد العزيز سليمان', 'aziz@example.com', '+249123456789', 'hash_cust_1', 'customer'),
(13, 'مريم عبد القادر', 'maryam@example.com', '+966501234567', 'hash_cust_2', 'customer');

-- إدخال حجز تجريبي (طيران تاركو) بالجنيه السوداني
INSERT OR IGNORE INTO bookings (id, booking_reference, customer_id, assigned_employee_id, service_code, service_provider, origin, destination, departure_date, passengers_count, passenger_names, total_amount, currency, status, notes) VALUES
(1, 'BK-2026-TR884', 12, 2, 'flight', 'Tarco Aviation', 'بورتسودان (PZU)', 'القاهرة (CAI)', '2026-11-20', 1, 'عبد العزيز سليمان أحمد', 1250000.00, 'SDG', 'in_review', 'طلب حجز رحلة تاركو المباشرة رقم 3W-112');

-- إدخال مستند مرفق تجريبي
INSERT OR IGNORE INTO documents (id, booking_id, customer_id, doc_type, file_name, file_url, verified_status, verified_by_employee_id) VALUES
(1, 1, 12, 'passport', 'passport_aziz_2026.jpg', 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=600&q=80', 'pending', 2);

-- إدخال رسائل شات أولية بالجنيه السوداني
INSERT OR IGNORE INTO chat_messages (id, booking_id, sender_id, sender_type, message_text) VALUES
(1, 1, 12, 'customer', 'مرحباً، لقد قمت برفع صورة جواز السفر وأريد تأكيد مقعد على رحلة تاركو من بورتسودان إلى القاهرة يوم 20 نوفمبر.'),
(2, 1, 2, 'employee', 'أهلاً بك أستاذ عبد العزيز. تم استلام المستندات وجاري مطابقتها عبر نظام TT Interactive لإصدار تأكيد الحجز المبدئي وإرسال الفاتورة بقيمة 1,250,000 ج.س.');
