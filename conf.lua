function love.conf(t)
    -- إعدادات النافذة
    t.window.title = "Catch the Cherry"    -- اسم اللعبة
    t.window.icon = "icon.png"            -- تعيين صورة الكوب كأيقونة للعبة
    t.window.width = 600                   -- العرض المطلوب
    t.window.height = 1024                 -- الطول المطلوب
    t.window.resizable = false             -- تثبيت الحجم لمنع التشويه

    -- إعدادات النظام
    t.modules.joystick = false             -- إيقاف الوحدات غير المستخدمة لتوفير الذاكرة
    t.modules.physics = false
    
    -- إعدادات الأندرويد
    t.externalstorage = true               -- للسماح بحفظ البيانات خارجياً إذا احتجت مستقبلاً
end