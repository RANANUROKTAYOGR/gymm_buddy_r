import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gym_buddy.db');
    await _ensureUserBadgesTable(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 17, // Version 17: add sample appointments
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _ensureUserBadgesTable(Database db) async {
    // Check if user_badges table exists
    var tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='user_badges'"
    );
    
    if (tables.isEmpty) {
      print('🔧 user_badges tablosu bulunamadı, oluşturuluyor...');
      await db.execute('''
        CREATE TABLE user_badges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          badge_code TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          earned_at TEXT NOT NULL,
          UNIQUE(user_id, badge_code),
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
      print('✅ user_badges tablosu başarıyla oluşturuldu');
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new tables for version 2
      await _createNewTables(db);
    }
    if (oldVersion < 3) {
      // Version 3: Update workout_sessions with nullable fields
      // Already handled in schema
    }
    if (oldVersion < 4) {
      // Version 4: Add photo_path to body_measurements
      await db.execute(
        'ALTER TABLE body_measurements ADD COLUMN photo_path TEXT',
      );
    }
    if (oldVersion < 5) {
      // Version 5: Add date_of_birth, height, weight to users
      await db.execute('ALTER TABLE users ADD COLUMN date_of_birth TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN height REAL');
      await db.execute('ALTER TABLE users ADD COLUMN weight REAL');
    }
    if (oldVersion < 6) {
      // Version 6: Add opening_time, closing_time, facilities to gym_branches
      await db.execute('ALTER TABLE gym_branches ADD COLUMN opening_time TEXT');
      await db.execute('ALTER TABLE gym_branches ADD COLUMN closing_time TEXT');
      await db.execute('ALTER TABLE gym_branches ADD COLUMN facilities TEXT');
    }
    if (oldVersion < 7) {
      // Version 7: Add hydration_logs table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS hydration_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          amount_ml INTEGER NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 8) {
      // Version 8: Add video_url to equipment
      await db.execute('ALTER TABLE equipment ADD COLUMN video_url TEXT');
    }
    if (oldVersion < 9) {
      // Version 9: Add user_badges table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_badges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          badge_code TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          earned_at TEXT NOT NULL,
          UNIQUE(user_id, badge_code),
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 10) {
      // Version 10: Add subscriptions, appointments, group_classes, diet_plans, user_diet, trainers
      await db.execute('''
        CREATE TABLE IF NOT EXISTS subscriptions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          gym_branch_id INTEGER NOT NULL,
          subscription_type TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          amount REAL NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (gym_branch_id) REFERENCES gym_branches (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS appointments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          trainer_id INTEGER,
          gym_branch_id INTEGER NOT NULL,
          appointment_date TEXT NOT NULL,
          notes TEXT,
          status TEXT NOT NULL DEFAULT 'scheduled',
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (gym_branch_id) REFERENCES gym_branches (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS group_classes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          gym_branch_id INTEGER NOT NULL,
          class_name TEXT NOT NULL,
          instructor_name TEXT,
          max_capacity INTEGER NOT NULL,
          schedule TEXT NOT NULL,
          duration INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (gym_branch_id) REFERENCES gym_branches (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS diet_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          daily_calories INTEGER NOT NULL,
          protein_percentage INTEGER NOT NULL,
          carbs_percentage INTEGER NOT NULL,
          fat_percentage INTEGER NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_diet (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          diet_plan_id INTEGER NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (diet_plan_id) REFERENCES diet_plans (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS trainers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          gym_branch_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          specialization TEXT,
          phone TEXT,
          email TEXT,
          bio TEXT,
          photo_url TEXT,
          years_of_experience INTEGER,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (gym_branch_id) REFERENCES gym_branches (id) ON DELETE CASCADE
        )
      ''');
      
      // Seed diet plans
      await db.insert('diet_plans', {
        'name': 'Keto Diyeti',
        'description': 'Yüksek yağ, düşük karbonhidrat diyeti',
        'daily_calories': 2000,
        'protein_percentage': 25,
        'carbs_percentage': 5,
        'fat_percentage': 70,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('diet_plans', {
        'name': 'Akdeniz Diyeti',
        'description': 'Dengeli ve sağlıklı beslenme',
        'daily_calories': 2200,
        'protein_percentage': 20,
        'carbs_percentage': 50,
        'fat_percentage': 30,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('diet_plans', {
        'name': 'Protein Ağırlıklı',
        'description': 'Kas kütlesi artışı için ideal',
        'daily_calories': 2500,
        'protein_percentage': 40,
        'carbs_percentage': 35,
        'fat_percentage': 25,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    if (oldVersion < 11) {
      // Version 11: Add sample trainers, group classes, and subscriptions
      // Get first gym branch id
      final branches = await db.query('gym_branches', limit: 1);
      if (branches.isNotEmpty) {
        final branchId = branches.first['id'] as int;
        
        // Add trainers
        await db.insert('trainers', {
          'gym_branch_id': branchId,
          'name': 'Ahmet Yılmaz',
          'specialization': 'Kişisel Antrenman, Kuvvet',
          'phone': '+90 532 111 2233',
          'email': 'ahmet.yilmaz@gymbud.com',
          'bio': '10 yıllık deneyime sahip sertifikalı kişisel antrenör. Kuvvet antrenmanı ve vücut geliştirme konularında uzman.',
          'photo_url': 'https://randomuser.me/api/portraits/men/1.jpg',
          'years_of_experience': 10,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('trainers', {
          'gym_branch_id': branchId,
          'name': 'Zeynep Kaya',
          'specialization': 'Pilates, Yoga',
          'phone': '+90 532 444 5566',
          'email': 'zeynep.kaya@gymbud.com',
          'bio': 'Pilates ve yoga eğitmeni. Esneklik ve denge konularında 8 yıllık tecrübe.',
          'photo_url': 'https://randomuser.me/api/portraits/women/2.jpg',
          'years_of_experience': 8,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('trainers', {
          'gym_branch_id': branchId,
          'name': 'Mehmet Demir',
          'specialization': 'CrossFit, Fonksiyonel Antrenman',
          'phone': '+90 532 777 8899',
          'email': 'mehmet.demir@gymbud.com',
          'bio': 'CrossFit Level 2 sertifikalı antrenör. Fonksiyonel fitness ve kondisyon geliştirme konularında uzman.',
          'photo_url': 'https://randomuser.me/api/portraits/men/3.jpg',
          'years_of_experience': 6,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('trainers', {
          'gym_branch_id': branchId,
          'name': 'Ayşe Öztürk',
          'specialization': 'Beslenme, Kilo Yönetimi',
          'phone': '+90 532 222 3344',
          'email': 'ayse.ozturk@gymbud.com',
          'bio': 'Diyetisyen ve fitness koçu. Kilo verme ve sağlıklı beslenme programları konusunda 12 yıllık deneyim.',
          'photo_url': 'https://randomuser.me/api/portraits/women/4.jpg',
          'years_of_experience': 12,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('trainers', {
          'gym_branch_id': branchId,
          'name': 'Can Arslan',
          'specialization': 'Kardio, Dayanıklılık',
          'phone': '+90 532 555 6677',
          'email': 'can.arslan@gymbud.com',
          'bio': 'Maraton koşucusu ve kardiyovasküler antrenman uzmanı. Dayanıklılık sporları için 7 yıllık coaching tecrübesi.',
          'photo_url': 'https://randomuser.me/api/portraits/men/5.jpg',
          'years_of_experience': 7,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Add group classes
        await db.insert('group_classes', {
          'gym_branch_id': branchId,
          'class_name': 'Sabah Yoga',
          'instructor_name': 'Zeynep Kaya',
          'max_capacity': 20,
          'schedule': 'Pazartesi, Çarşamba, Cuma - 07:00',
          'duration': 60,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('group_classes', {
          'gym_branch_id': branchId,
          'class_name': 'Spinning',
          'instructor_name': 'Can Arslan',
          'max_capacity': 15,
          'schedule': 'Salı, Perşembe - 18:00',
          'duration': 45,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('group_classes', {
          'gym_branch_id': branchId,
          'class_name': 'CrossFit WOD',
          'instructor_name': 'Mehmet Demir',
          'max_capacity': 12,
          'schedule': 'Pazartesi, Çarşamba, Cuma - 19:00',
          'duration': 60,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('group_classes', {
          'gym_branch_id': branchId,
          'class_name': 'Pilates Mat',
          'instructor_name': 'Zeynep Kaya',
          'max_capacity': 15,
          'schedule': 'Salı, Perşembe, Cumartesi - 10:00',
          'duration': 50,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('group_classes', {
          'gym_branch_id': branchId,
          'class_name': 'HIIT Bootcamp',
          'instructor_name': 'Ahmet Yılmaz',
          'max_capacity': 20,
          'schedule': 'Çarşamba, Cuma - 18:30',
          'duration': 45,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        await db.insert('group_classes', {
          'gym_branch_id': branchId,
          'class_name': 'Zumba',
          'instructor_name': 'Ayşe Öztürk',
          'max_capacity': 25,
          'schedule': 'Pazartesi, Perşembe - 19:30',
          'duration': 55,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Add sample subscription for first user
        final users = await db.query('users', limit: 1);
        if (users.isNotEmpty) {
          final userId = users.first['id'] as int;
          await db.insert('subscriptions', {
            'user_id': userId,
            'gym_branch_id': branchId,
            'subscription_type': 'Premium',
            'start_date': DateTime.now().toIso8601String(),
            'end_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
            'amount': 1200.0,
            'is_active': 1,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    }
    if (oldVersion < 12) {
      // Version 12: Ensure user_badges table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_badges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          badge_code TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          earned_at TEXT NOT NULL,
          UNIQUE(user_id, badge_code),
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 13) {
      // Version 13: Add video_url to exercises
      await db.execute('ALTER TABLE exercises ADD COLUMN video_url TEXT');
    }
    if (oldVersion < 14) {
      // Version 14: Add image fields to exercises
      await db.execute('ALTER TABLE exercises ADD COLUMN thumbnail_image TEXT');
      await db.execute('ALTER TABLE exercises ADD COLUMN step_image_1 TEXT');
      await db.execute('ALTER TABLE exercises ADD COLUMN step_image_2 TEXT');
    }
    if (oldVersion < 15) {
      // Version 15: add time fields to appointments and group_classes
      await db.execute('ALTER TABLE appointments ADD COLUMN appointment_time TEXT');
      await db.execute('ALTER TABLE group_classes ADD COLUMN class_date_time TEXT');
      
      // Mevcut grup derslerine örnek tarih ve saat ekle
      final now = DateTime.now();
      final classes = await db.query('group_classes');
      
      for (var i = 0; i < classes.length; i++) {
        final classData = classes[i];
        final classId = classData['id'] as int;
        
        // Haftanın farklı günlerine ve saatlerine dağıt
        DateTime classDateTime;
        switch (i % 6) {
          case 0:
            classDateTime = now.add(Duration(days: 1)).copyWith(hour: 13, minute: 0, second: 0, millisecond: 0);
            break;
          case 1:
            classDateTime = now.add(Duration(days: 2)).copyWith(hour: 14, minute: 0, second: 0, millisecond: 0);
            break;
          case 2:
            classDateTime = now.add(Duration(days: 3)).copyWith(hour: 15, minute: 0, second: 0, millisecond: 0);
            break;
          case 3:
            classDateTime = now.add(Duration(days: 4)).copyWith(hour: 16, minute: 0, second: 0, millisecond: 0);
            break;
          case 4:
            classDateTime = now.add(Duration(days: 5)).copyWith(hour: 17, minute: 0, second: 0, millisecond: 0);
            break;
          default:
            classDateTime = now.add(Duration(days: 6)).copyWith(hour: 18, minute: 0, second: 0, millisecond: 0);
        }
        
        await db.update(
          'group_classes',
          {'class_date_time': classDateTime.toIso8601String()},
          where: 'id = ?',
          whereArgs: [classId],
        );
      }
    }
    if (oldVersion < 16) {
      // Version 16: update existing group classes with datetime
      final now = DateTime.now();
      final classes = await db.query('group_classes');
      
      for (var i = 0; i < classes.length; i++) {
        final classData = classes[i];
        final classId = classData['id'] as int;
        
        // Haftanın farklı günlerine ve saatlerine dağıt
        DateTime classDateTime;
        switch (i % 6) {
          case 0:
            classDateTime = now.add(Duration(days: 1)).copyWith(hour: 13, minute: 0, second: 0, millisecond: 0);
            break;
          case 1:
            classDateTime = now.add(Duration(days: 2)).copyWith(hour: 14, minute: 0, second: 0, millisecond: 0);
            break;
          case 2:
            classDateTime = now.add(Duration(days: 3)).copyWith(hour: 15, minute: 0, second: 0, millisecond: 0);
            break;
          case 3:
            classDateTime = now.add(Duration(days: 4)).copyWith(hour: 16, minute: 0, second: 0, millisecond: 0);
            break;
          case 4:
            classDateTime = now.add(Duration(days: 5)).copyWith(hour: 17, minute: 0, second: 0, millisecond: 0);
            break;
          default:
            classDateTime = now.add(Duration(days: 6)).copyWith(hour: 18, minute: 0, second: 0, millisecond: 0);
        }
        
        await db.update(
          'group_classes',
          {'class_date_time': classDateTime.toIso8601String()},
          where: 'id = ?',
          whereArgs: [classId],
        );
      }
    }
    if (oldVersion < 17) {
      // Version 17: add sample appointments
      final users = await db.query('users', limit: 1);
      if (users.isNotEmpty) {
        final userId = users.first['id'] as int;
        final now = DateTime.now();
        
        // 3 örnek randevu ekle (farklı günlerde)
        await db.insert('appointments', {
          'user_id': userId,
          'trainer_id': 1,
          'gym_branch_id': 1,
          'appointment_date': now.add(const Duration(days: 2)).toIso8601String(),
          'notes': 'Kişisel antrenman - Kuvvet çalışması',
          'status': 'scheduled',
          'created_at': now.toIso8601String(),
        });
        
        await db.insert('appointments', {
          'user_id': userId,
          'trainer_id': 1,
          'gym_branch_id': 1,
          'appointment_date': now.add(const Duration(days: 5)).toIso8601String(),
          'notes': 'Beslenme danışmanlığı',
          'status': 'scheduled',
          'created_at': now.toIso8601String(),
        });
        
        await db.insert('appointments', {
          'user_id': userId,
          'trainer_id': 1,
          'gym_branch_id': 1,
          'appointment_date': now.add(const Duration(days: 7)).toIso8601String(),
          'notes': 'Ölçüm ve program güncellemesi',
          'status': 'scheduled',
          'created_at': now.toIso8601String(),
        });
      }
    }
  }

  Future<void> _createNewTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS gym_branches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT,
        phone TEXT,
        email TEXT,
        latitude REAL,
        longitude REAL,
        working_hours TEXT,
        opening_time TEXT,
        closing_time TEXT,
        facilities TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS equipment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gym_branch_id INTEGER,
        name TEXT NOT NULL,
        type TEXT,
        brand TEXT,
        model TEXT,
        qr_code TEXT,
        description TEXT,
        is_available INTEGER NOT NULL DEFAULT 1,
        last_maintenance_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (gym_branch_id) REFERENCES gym_branches (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS body_measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        measurement_date TEXT NOT NULL,
        weight REAL,
        height REAL,
        body_fat_percentage REAL,
        muscle_mass REAL,
        bmi REAL,
        chest REAL,
        waist REAL,
        hips REAL,
        biceps REAL,
        thighs REAL,
        calves REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        goal_type TEXT NOT NULL,
        target_metric TEXT,
        current_value REAL,
        target_value REAL,
        target_date TEXT,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        progress REAL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercise_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        image_url TEXT NOT NULL,
        image_type TEXT,
        order_index INTEGER,
        caption TEXT,
        is_primary INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. USER TABLE
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        date_of_birth TEXT,
        height REAL,
        weight REAL,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. GYM_BRANCH TABLE
    await db.execute('''
      CREATE TABLE gym_branches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT,
        phone TEXT,
        email TEXT,
        latitude REAL,
        longitude REAL,
        working_hours TEXT,
        opening_time TEXT,
        closing_time TEXT,
        facilities TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. EQUIPMENT TABLE
    await db.execute('''
      CREATE TABLE equipment (
          video_url TEXT,
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gym_branch_id INTEGER,
        name TEXT NOT NULL,
        type TEXT,
        brand TEXT,
        model TEXT,
        qr_code TEXT,
        description TEXT,
        is_available INTEGER NOT NULL DEFAULT 1,
        last_maintenance_date TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (gym_branch_id) REFERENCES gym_branches (id) ON DELETE CASCADE
      )
    ''');

    // 4. EXERCISE TABLE
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        muscle_group TEXT,
        equipment TEXT,
        video_url TEXT,
        thumbnail_image TEXT,
        step_image_1 TEXT,
        step_image_2 TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. WORKOUT_SESSION TABLE
    await db.execute('''
      CREATE TABLE workout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        session_type TEXT,
        total_duration INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 6. EXERCISE_LOG TABLE
    await db.execute('''
      CREATE TABLE exercise_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        order_in_session INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (workout_session_id) REFERENCES workout_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    // 7. SET_DETAILS TABLE
    await db.execute('''
      CREATE TABLE set_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_log_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight REAL,
        reps INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (exercise_log_id) REFERENCES exercise_logs (id) ON DELETE CASCADE
      )
    ''');

    // 8. BODY_MEASUREMENTS TABLE
    await db.execute('''
      CREATE TABLE body_measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        measurement_date TEXT NOT NULL,
        weight REAL,
        height REAL,
        body_fat_percentage REAL,
        muscle_mass REAL,
        bmi REAL,
        chest REAL,
        waist REAL,
        hips REAL,
        biceps REAL,
        thighs REAL,
        calves REAL,
        photo_path TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 9. USER_GOALS TABLE
    await db.execute('''
      CREATE TABLE user_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        goal_type TEXT NOT NULL,
        target_metric TEXT,
        current_value REAL,
        target_value REAL,
        target_date TEXT,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        progress REAL DEFAULT 0.0,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 10. EXERCISE_IMAGES TABLE
    await db.execute('''
      CREATE TABLE exercise_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        image_url TEXT NOT NULL,
        image_type TEXT,
        order_index INTEGER,
        caption TEXT,
        is_primary INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    // 11. HYDRATION_LOGS TABLE
    await db.execute('''
      CREATE TABLE hydration_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        amount_ml INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 12. SUBSCRIPTIONS TABLE
    await db.execute('''
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        gym_branch_id INTEGER NOT NULL,
        subscription_type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        amount REAL NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (gym_branch_id) REFERENCES gym_branches (id) ON DELETE CASCADE
      )
    ''');

    // 13. APPOINTMENTS TABLE
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        trainer_id INTEGER,
        gym_branch_id INTEGER NOT NULL,
        appointment_date TEXT NOT NULL,
        appointment_time TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'scheduled',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (gym_branch_id) REFERENCES gym_branches (id) ON DELETE CASCADE
      )
    ''');

    // 14. GROUP_CLASSES TABLE
    await db.execute('''
      CREATE TABLE group_classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gym_branch_id INTEGER NOT NULL,
        class_name TEXT NOT NULL,
        instructor_name TEXT,
        max_capacity INTEGER NOT NULL,
        schedule TEXT NOT NULL,
        duration INTEGER NOT NULL,
        class_date_time TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (gym_branch_id) REFERENCES gym_branches (id) ON DELETE CASCADE
      )
    ''');

    // 15. DIET_PLANS TABLE
    await db.execute('''
      CREATE TABLE diet_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        daily_calories INTEGER NOT NULL,
        protein_percentage INTEGER NOT NULL,
        carbs_percentage INTEGER NOT NULL,
        fat_percentage INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // 16. USER_DIET TABLE
    await db.execute('''
      CREATE TABLE user_diet (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        diet_plan_id INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (diet_plan_id) REFERENCES diet_plans (id) ON DELETE CASCADE
      )
    ''');

    // 17. TRAINERS TABLE
    await db.execute('''
      CREATE TABLE trainers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gym_branch_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        specialization TEXT,
        phone TEXT,
        email TEXT,
        bio TEXT,
        photo_url TEXT,
        years_of_experience INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (gym_branch_id) REFERENCES gym_branches (id) ON DELETE CASCADE
      )
    ''');

    // 18. USER_BADGES TABLE
    await db.execute('''
      CREATE TABLE user_badges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        badge_code TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        earned_at TEXT NOT NULL,
        UNIQUE(user_id, badge_code),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    // Sample gym branches with different locations in Istanbul
    final branch1Id = await db.insert('gym_branches', {
      'name': 'GymBuddy Merkez Kadıköy',
      'address': 'Caferağa Mahallesi, Moda Caddesi No:45',
      'city': 'İstanbul',
      'phone': '+90 216 555 0001',
      'email': 'kadikoy@gymbud.com',
      'latitude': 40.9917,
      'longitude': 29.0253,
      'opening_time': '06:00',
      'closing_time': '23:00',
      'facilities': 'Kardio, Ağırlık, Grup Dersleri, Sauna, Soyunma Odası',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('gym_branches', {
      'name': 'GymBuddy Beşiktaş',
      'address': 'Ortabahçe Caddesi No:78, Beşiktaş',
      'city': 'İstanbul',
      'phone': '+90 212 555 0002',
      'email': 'besiktas@gymbud.com',
      'latitude': 41.0426,
      'longitude': 29.0077,
      'opening_time': '07:00',
      'closing_time': '22:00',
      'facilities': 'Kardio, Ağırlık, Pilates, Yoga, Masaj',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('gym_branches', {
      'name': 'GymBuddy Nişantaşı Premium',
      'address': 'Teşvikiye Caddesi No:120, Şişli',
      'city': 'İstanbul',
      'phone': '+90 212 555 0003',
      'email': 'nisantasi@gymbud.com',
      'latitude': 41.0486,
      'longitude': 28.9939,
      'opening_time': '06:00',
      'closing_time': '00:00',
      'facilities': 'Kardio, Ağırlık, Grup Dersleri, SPA, Havuz, Kafe',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('gym_branches', {
      'name': 'GymBuddy Ataşehir',
      'address': 'Ataşehir Bulvarı No:234',
      'city': 'İstanbul',
      'phone': '+90 216 555 0004',
      'email': 'atasehir@gymbud.com',
      'latitude': 40.9829,
      'longitude': 29.1244,
      'opening_time': '05:00',
      'closing_time': '23:00',
      'facilities': 'Kardio, Ağırlık, TRX, CrossFit, Soyunma Odası',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('gym_branches', {
      'name': 'GymBuddy Levent',
      'address': '1. Levent Mahallesi, Bayar Caddesi No:56',
      'city': 'İstanbul',
      'phone': '+90 212 555 0005',
      'email': 'levent@gymbud.com',
      'latitude': 41.0762,
      'longitude': 29.0113,
      'opening_time': '06:30',
      'closing_time': '22:30',
      'facilities': 'Kardio, Ağırlık, Spinning, Box, Sauna',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Sample equipment with QR codes (for first branch)
    await db.insert('equipment', {
      'gym_branch_id': branch1Id,
      'name': 'Smith Machine',
      'type': 'Strength',
      'brand': 'Technogym',
      'model': 'Selection Pro',
      'qr_code': 'SMITH001',
      'video_url': 'https://www.youtube.com/watch?v=nV6hZx8L-i4',
      'description': 'Güvenli squat ve bench press için ideal',
      'is_available': 1,
      'last_maintenance_date': DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('equipment', {
      'gym_branch_id': branch1Id,
      'name': 'Leg Press',
      'type': 'Strength',
      'brand': 'Life Fitness',
      'model': 'Signature Series',
      'qr_code': 'LEGPRESS001',
      'video_url': 'https://www.youtube.com/watch?v=IZxyjW7MPJQ',
      'description': 'Bacak egzersizleri için profesyonel makine',
      'is_available': 1,
      'last_maintenance_date': DateTime.now()
          .subtract(const Duration(days: 15))
          .toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('equipment', {
      'gym_branch_id': branch1Id,
      'name': 'Cable Crossover',
      'type': 'Strength',
      'brand': 'Matrix',
      'model': 'Ultra',
      'qr_code': 'CABLE001',
      'video_url': 'https://www.youtube.com/watch?v=c3lUXtyBbWM',
      'description': 'Göğüs ve omuz egzersizleri',
      'is_available': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Sample exercises
    await db.insert('exercises', {
      'name': 'Bench Press',
      'description': 'Göğüs egzersizi',
      'muscle_group': 'Chest',
      'equipment': 'Barbell',
      'video_url': 'https://www.youtube.com/watch?v=rT7DgCr-3pg',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('exercises', {
      'name': 'Squat',
      'description': 'Bacak egzersizi',
      'muscle_group': 'Legs',
      'equipment': 'Barbell',
      'video_url': 'https://www.youtube.com/watch?v=ultWZbUMPL8',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('exercises', {
      'name': 'Deadlift',
      'description': 'Sırt egzersizi',
      'muscle_group': 'Back',
      'equipment': 'Barbell',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed diet plans
    await db.insert('diet_plans', {
      'name': 'Keto Diyeti',
      'description': 'Düşük karbonhidrat, yüksek yağ içerikli beslenme planı',
      'daily_calories': 2000,
      'protein_percentage': 25,
      'carbs_percentage': 5,
      'fat_percentage': 70,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('diet_plans', {
      'name': 'Akdeniz Diyeti',
      'description': 'Zeytinyağı, balık, sebze ve meyve ağırlıklı dengeli beslenme',
      'daily_calories': 2200,
      'protein_percentage': 20,
      'carbs_percentage': 50,
      'fat_percentage': 30,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('diet_plans', {
      'name': 'Protein Ağırlıklı',
      'description': 'Kas gelişimi için yüksek protein içerikli plan',
      'daily_calories': 2500,
      'protein_percentage': 40,
      'carbs_percentage': 35,
      'fat_percentage': 25,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed trainers
    await db.insert('trainers', {
      'gym_branch_id': branch1Id,
      'name': 'Ahmet Yılmaz',
      'specialization': 'Kişisel Antrenman, Kuvvet',
      'phone': '+90 532 111 2233',
      'email': 'ahmet.yilmaz@gymbud.com',
      'bio': '10 yıllık deneyime sahip sertifikalı kişisel antrenör. Kuvvet antrenmanı ve vücut geliştirme konularında uzman.',
      'photo_url': 'https://randomuser.me/api/portraits/men/1.jpg',
      'years_of_experience': 10,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('trainers', {
      'gym_branch_id': branch1Id,
      'name': 'Zeynep Kaya',
      'specialization': 'Pilates, Yoga',
      'phone': '+90 532 444 5566',
      'email': 'zeynep.kaya@gymbud.com',
      'bio': 'Pilates ve yoga eğitmeni. Esneklik ve denge konularında 8 yıllık tecrübe.',
      'photo_url': 'https://randomuser.me/api/portraits/women/2.jpg',
      'years_of_experience': 8,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('trainers', {
      'gym_branch_id': branch1Id,
      'name': 'Mehmet Demir',
      'specialization': 'CrossFit, Fonksiyonel Antrenman',
      'phone': '+90 532 777 8899',
      'email': 'mehmet.demir@gymbud.com',
      'bio': 'CrossFit Level 2 sertifikalı antrenör. Fonksiyonel fitness ve kondisyon geliştirme konularında uzman.',
      'photo_url': 'https://randomuser.me/api/portraits/men/3.jpg',
      'years_of_experience': 6,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('trainers', {
      'gym_branch_id': branch1Id,
      'name': 'Ayşe Öztürk',
      'specialization': 'Beslenme, Kilo Yönetimi',
      'phone': '+90 532 222 3344',
      'email': 'ayse.ozturk@gymbud.com',
      'bio': 'Diyetisyen ve fitness koçu. Kilo verme ve sağlıklı beslenme programları konusunda 12 yıllık deneyim.',
      'photo_url': 'https://randomuser.me/api/portraits/women/4.jpg',
      'years_of_experience': 12,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('trainers', {
      'gym_branch_id': branch1Id,
      'name': 'Can Arslan',
      'specialization': 'Kardio, Dayanıklılık',
      'phone': '+90 532 555 6677',
      'email': 'can.arslan@gymbud.com',
      'bio': 'Maraton koşucusu ve kardiyovasküler antrenman uzmanı. Dayanıklılık sporları için 7 yıllık coaching tecrübesi.',
      'photo_url': 'https://randomuser.me/api/portraits/men/5.jpg',
      'years_of_experience': 7,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed group classes
    await db.insert('group_classes', {
      'gym_branch_id': branch1Id,
      'class_name': 'Sabah Yoga',
      'instructor_name': 'Zeynep Kaya',
      'max_capacity': 20,
      'schedule': 'Pazartesi, Çarşamba, Cuma - 07:00',
      'duration': 60,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('group_classes', {
      'gym_branch_id': branch1Id,
      'class_name': 'Spinning',
      'instructor_name': 'Can Arslan',
      'max_capacity': 15,
      'schedule': 'Salı, Perşembe - 18:00',
      'duration': 45,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('group_classes', {
      'gym_branch_id': branch1Id,
      'class_name': 'CrossFit WOD',
      'instructor_name': 'Mehmet Demir',
      'max_capacity': 12,
      'schedule': 'Pazartesi, Çarşamba, Cuma - 19:00',
      'duration': 60,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('group_classes', {
      'gym_branch_id': branch1Id,
      'class_name': 'Pilates Mat',
      'instructor_name': 'Zeynep Kaya',
      'max_capacity': 15,
      'schedule': 'Salı, Perşembe, Cumartesi - 10:00',
      'duration': 50,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('group_classes', {
      'gym_branch_id': branch1Id,
      'class_name': 'HIIT Bootcamp',
      'instructor_name': 'Ahmet Yılmaz',
      'max_capacity': 20,
      'schedule': 'Çarşamba, Cuma - 18:30',
      'duration': 45,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('group_classes', {
      'gym_branch_id': branch1Id,
      'class_name': 'Zumba',
      'instructor_name': 'Ayşe Öztürk',
      'max_capacity': 25,
      'schedule': 'Pazartesi, Perşembe - 19:30',
      'duration': 55,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed a sample user and subscription
    final userId = await db.insert('users', {
      'name': 'Demo Kullanıcı',
      'email': 'demo@gymbud.com',
      'date_of_birth': '1990-01-01',
      'height': 175.0,
      'weight': 75.0,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed sample appointments
    final trainerId = await db.rawQuery(
      'SELECT id FROM trainers WHERE name = ? LIMIT 1',
      ['Ahmet Yılmaz']
    );
    if (trainerId.isNotEmpty) {
      final tId = trainerId.first['id'] as int;
      
      await db.insert('appointments', {
        'user_id': userId,
        'trainer_id': tId,
        'gym_branch_id': branch1Id,
        'appointment_date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'notes': 'Kişisel antrenman programı oluşturma ve form kontrolü',
        'status': 'scheduled',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('appointments', {
        'user_id': userId,
        'trainer_id': tId,
        'gym_branch_id': branch1Id,
        'appointment_date': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        'notes': 'İlerleme takibi ve program güncellemesi',
        'status': 'scheduled',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    await db.insert('subscriptions', {
      'user_id': userId,
      'gym_branch_id': branch1Id,
      'subscription_type': 'Premium',
      'start_date': DateTime.now().toIso8601String(),
      'end_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      'amount': 1200.0,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // User operations
  Future<User> createUser(User user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<User> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return user;
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  // Exercise operations
  Future<Exercise> createExercise(Exercise exercise) async {
    final db = await database;
    final id = await db.insert('exercises', exercise.toMap());
    return exercise.copyWith(id: id);
  }

  Future<List<Exercise>> getAllExercises() async {
    final db = await database;
    final result = await db.query('exercises');
    return result.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<Exercise?> getExercise(int id) async {
    final db = await database;
    final result = await db.query(
      'exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Exercise.fromMap(result.first);
    }
    return null;
  }

  Future<List<Exercise>> getExercisesByEquipment(String equipmentName) async {
    final db = await database;
    final result = await db.query(
      'exercises',
      where: 'equipment = ?',
      whereArgs: [equipmentName],
    );
    return result.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<Exercise?> getExerciseByEquipmentName(String equipmentName) async {
    final db = await database;
    final result = await db.query(
      'exercises',
      where: 'equipment LIKE ?',
      whereArgs: ['%$equipmentName%'],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Exercise.fromMap(result.first);
    }
    return null;
  }

  Future<int> deleteExercise(int id) async {
    final db = await database;
    return await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getLastSetDetailsForExercise(
    int userId,
    int exerciseId,
  ) async {
    final db = await database;

    // Get the latest exercise log for this user and exercise
    final exerciseLogResult = await db.rawQuery(
      '''
      SELECT el.id 
      FROM exercise_logs el
      INNER JOIN workout_sessions ws ON el.workout_session_id = ws.id
      WHERE ws.user_id = ? AND el.exercise_id = ?
      ORDER BY ws.start_time DESC
      LIMIT 1
    ''',
      [userId, exerciseId],
    );

    if (exerciseLogResult.isEmpty) {
      return null;
    }

    final exerciseLogId = exerciseLogResult.first['id'] as int;

    // Get the last set details
    final setDetailsResult = await db.query(
      'set_details',
      where: 'exercise_log_id = ?',
      whereArgs: [exerciseLogId],
      orderBy: 'set_number DESC',
      limit: 1,
    );

    if (setDetailsResult.isEmpty) {
      return null;
    }

    return setDetailsResult.first;
  }

  // WorkoutSession operations
  Future<WorkoutSession> createWorkoutSession(WorkoutSession session) async {
    final db = await database;
    final id = await db.insert('workout_sessions', session.toMap());
    return session.copyWith(id: id);
  }

  Future<int> getWorkoutSessionCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM workout_sessions WHERE user_id = ?',
      [userId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<WorkoutSession>> getWorkoutSessionsByUser(
    int userId,
    int limit,
  ) async {
    final db = await database;
    final result = await db.query(
      'workout_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return result.map((map) => WorkoutSession.fromMap(map)).toList();
  }

  Future<List<WorkoutSession>> getLastDaysActivity(int userId, int days) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days));
    final result = await db.query(
      'workout_sessions',
      where: 'user_id = ? AND start_time >= ?',
      whereArgs: [userId, since.toIso8601String()],
      orderBy: 'start_time DESC',
    );
    return result.map((map) => WorkoutSession.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getLastDaysActivityChart(
    int userId,
    int days,
  ) async {
    final sessions = await getLastDaysActivity(userId, days);

    // Gün gruplandırması
    final Map<String, int> dayCount = {};
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dayCount[dateKey] = 0;
    }

    // Antrenmanları say
    for (var session in sessions) {
      final dateKey =
          '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}-${session.startTime.day.toString().padLeft(2, '0')}';
      if (dayCount.containsKey(dateKey)) {
        dayCount[dateKey] = (dayCount[dateKey] ?? 0) + 1;
      }
    }

    // Gün adlarını ekle (Ptz, Çrş, vb)
    final dayNames = ['Ptz', 'Cmt', 'Paz', 'Pzt', 'Sly', 'Çrş', 'Prş'];
    final result = <Map<String, dynamic>>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      result.add({
        'day': dayNames[date.weekday - 1],
        'date': dateKey,
        'count': dayCount[dateKey] ?? 0,
      });
    }

    return result;
  }

  // Get monthly volume data (weight * reps * sets) for line chart
  Future<List<Map<String, dynamic>>> getMonthlyVolumeData(int userId) async {
    final db = await database;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final result = await db.rawQuery(
      '''
      SELECT 
        DATE(ws.start_time) as date,
        SUM(sd.weight * sd.reps) as total_volume
      FROM set_details sd
      INNER JOIN exercise_logs el ON sd.exercise_log_id = el.id
      INNER JOIN workout_sessions ws ON el.workout_session_id = ws.id
      WHERE ws.user_id = ? 
        AND ws.start_time >= ?
        AND sd.weight IS NOT NULL
        AND sd.reps IS NOT NULL
      GROUP BY DATE(ws.start_time)
      ORDER BY date ASC
    ''',
      [userId, thirtyDaysAgo.toIso8601String()],
    );

    return result
        .map(
          (row) => {
            'date': row['date'] as String,
            'volume': (row['total_volume'] as num?)?.toDouble() ?? 0.0,
          },
        )
        .toList();
  }

  // Get body weight measurements for bar chart
  Future<List<Map<String, dynamic>>> getBodyWeightHistory(
    int userId,
    int days,
  ) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days));

    final result = await db.query(
      'body_measurements',
      columns: ['measurement_date', 'weight'],
      where: 'user_id = ? AND measurement_date >= ? AND weight IS NOT NULL',
      whereArgs: [userId, since.toIso8601String()],
      orderBy: 'measurement_date ASC',
    );

    return result
        .map(
          (row) => {
            'date': DateTime.parse(row['measurement_date'] as String),
            'weight': (row['weight'] as num).toDouble(),
          },
        )
        .toList();
  }

  // Get muscle group distribution for pie chart
  Future<List<Map<String, dynamic>>> getMuscleGroupDistribution(
    int userId,
  ) async {
    final db = await database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final result = await db.rawQuery(
      '''
      SELECT 
        e.muscle_group,
        COUNT(*) as count
      FROM exercise_logs el
      INNER JOIN exercises e ON el.exercise_id = e.id
      INNER JOIN workout_sessions ws ON el.workout_session_id = ws.id
      WHERE ws.user_id = ?
        AND ws.start_time >= ?
        AND e.muscle_group IS NOT NULL
      GROUP BY e.muscle_group
      ORDER BY count DESC
    ''',
      [userId, thirtyDaysAgo.toIso8601String()],
    );

    return result
        .map(
          (row) => {
            'muscleGroup': row['muscle_group'] as String,
            'count': row['count'] as int,
          },
        )
        .toList();
  }

  // Get or create today's workout session for a user
  Future<WorkoutSession> getOrCreateTodayWorkoutSession(int userId) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Check if there's already a session for today
    final result = await db.query(
      'workout_sessions',
      where: 'user_id = ? AND start_time >= ? AND start_time < ?',
      whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return WorkoutSession.fromMap(result.first);
    }

    // Create a new session for today
    final newSession = WorkoutSession(
      userId: userId,
      startTime: DateTime.now(),
      sessionType: 'QR Scan Session',
      createdAt: DateTime.now(),
    );

    final id = await db.insert('workout_sessions', newSession.toMap());
    return newSession.copyWith(id: id);
  }

  // ExerciseLog operations
  Future<ExerciseLog> createExerciseLog(ExerciseLog log) async {
    final db = await database;
    final id = await db.insert('exercise_logs', log.toMap());
    return log.copyWith(id: id);
  }

  Future<List<ExerciseLog>> getExerciseLogsBySession(int sessionId) async {
    final db = await database;
    final result = await db.query(
      'exercise_logs',
      where: 'workout_session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'order_in_session ASC',
    );
    return result.map((map) => ExerciseLog.fromMap(map)).toList();
  }

  // SetDetails operations
  Future<SetDetails> createSetDetails(SetDetails setDetails) async {
    final db = await database;
    final id = await db.insert('set_details', setDetails.toMap());
    return setDetails.copyWith(id: id);
  }

  Future<List<SetDetails>> getSetDetailsByLog(int logId) async {
    final db = await database;
    final result = await db.query(
      'set_details',
      where: 'exercise_log_id = ?',
      whereArgs: [logId],
      orderBy: 'set_number ASC',
    );
    return result.map((map) => SetDetails.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Veritabanını tamamen sil ve yeniden oluştur (Geliştirme amaçlı)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gym_buddy.db');

    // Önce bağlantıyı kapat
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Veritabanı dosyasını sil
    await databaseFactory.deleteDatabase(path);
  }

  // ==================== GYM_BRANCH OPERATIONS ====================
  Future<GymBranch> createGymBranch(GymBranch branch) async {
    final db = await database;
    final id = await db.insert('gym_branches', branch.toMap());
    return GymBranch(
      id: id,
      name: branch.name,
      address: branch.address,
      city: branch.city,
      phone: branch.phone,
      email: branch.email,
      latitude: branch.latitude,
      longitude: branch.longitude,
      openingTime: branch.openingTime,
      closingTime: branch.closingTime,
      facilities: branch.facilities,
      isActive: branch.isActive,
      createdAt: branch.createdAt,
    );
  }

  Future<List<GymBranch>> getAllGymBranches() async {
    final db = await database;
    final result = await db.query('gym_branches', where: 'is_active = 1');
    return result.map((map) => GymBranch.fromMap(map)).toList();
  }

  Future<GymBranch?> getGymBranch(int id) async {
    final db = await database;
    final result = await db.query(
      'gym_branches',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return GymBranch.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateGymBranch(GymBranch branch) async {
    final db = await database;
    return await db.update(
      'gym_branches',
      branch.toMap(),
      where: 'id = ?',
      whereArgs: [branch.id],
    );
  }

  Future<int> deleteGymBranch(int id) async {
    final db = await database;
    return await db.delete('gym_branches', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== EQUIPMENT OPERATIONS ====================
  Future<Equipment> createEquipment(Equipment equipment) async {
    final db = await database;
    final id = await db.insert('equipment', equipment.toMap());
    return Equipment(
      id: id,
      gymBranchId: equipment.gymBranchId,
      name: equipment.name,
      type: equipment.type,
      brand: equipment.brand,
      model: equipment.model,
      qrCode: equipment.qrCode,
      description: equipment.description,
      isAvailable: equipment.isAvailable,
      lastMaintenanceDate: equipment.lastMaintenanceDate,
      createdAt: equipment.createdAt,
    );
  }

  Future<List<Equipment>> getAllEquipment() async {
    final db = await database;
    final result = await db.query('equipment');
    return result.map((map) => Equipment.fromMap(map)).toList();
  }

  Future<List<Equipment>> getEquipmentByBranch(int branchId) async {
    final db = await database;
    final result = await db.query(
      'equipment',
      where: 'gym_branch_id = ? AND is_available = 1',
      whereArgs: [branchId],
    );
    return result.map((map) => Equipment.fromMap(map)).toList();
  }

  Future<Equipment?> getEquipmentByQRCode(String qrCode) async {
    final db = await database;
    final result = await db.query(
      'equipment',
      where: 'qr_code = ?',
      whereArgs: [qrCode],
    );
    if (result.isNotEmpty) {
      return Equipment.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateEquipment(Equipment equipment) async {
    final db = await database;
    return await db.update(
      'equipment',
      equipment.toMap(),
      where: 'id = ?',
      whereArgs: [equipment.id],
    );
  }

  Future<int> deleteEquipment(int id) async {
    final db = await database;
    return await db.delete('equipment', where: 'id = ?', whereArgs: [id]);
  }

  // Update equipment video URLs
  Future<void> updateEquipmentVideoUrls() async {
    final db = await database;
    
    // Sample YouTube URLs for equipment
    final videoUrls = {
      'Bench Press': 'https://www.youtube.com/watch?v=SCVCLChPQFY',
      'Squat Rack': 'https://www.youtube.com/watch?v=gcNh17Ckjgg',
      'Leg Press': 'https://www.youtube.com/watch?v=WJqCq6Xf1u4', // Updated (Planet Fitness)
      'Treadmill': 'https://www.youtube.com/watch?v=Z5rJ1q3F1_k', // Updated (Planet Fitness)
      'Dumbbells': 'https://www.youtube.com/watch?v=eGo4IYlbE5g',
      'Cable Crossover': 'https://www.youtube.com/watch?v=IweDW-R8sMg', // Updated (Planet Fitness)
      'Rowing Machine': 'https://www.youtube.com/watch?v=UC_7O_h59v4', // Updated (Planet Fitness)
      'Elliptical': 'https://www.youtube.com/watch?v=4Ra5VlR3kJM',
      'Smith Machine': 'https://www.youtube.com/watch?v=wX-4y8b7i7k', // Updated (Planet Fitness)
      'Lat Pulldown': 'https://www.youtube.com/watch?v=CAwf7n6Luuc',
      'Leg Extension': 'https://www.youtube.com/watch?v=YyvSfVjQeL0',
      'Stationary Bike': 'https://www.youtube.com/watch?v=4h-p4Ww7aCg', // Added & Updated (Planet Fitness)
    };

    for (var entry in videoUrls.entries) {
      await db.rawUpdate(
        'UPDATE equipment SET video_url = ? WHERE name LIKE ?',
        [entry.value, '%${entry.key}%'],
      );
    }
    
    print('✅ Ekipman video URL\'leri güncellendi');
  }

  // ==================== BODY_MEASUREMENTS OPERATIONS ====================
  Future<BodyMeasurements> createBodyMeasurement(
    BodyMeasurements measurement,
  ) async {
    final db = await database;
    final id = await db.insert('body_measurements', measurement.toMap());
    return BodyMeasurements(
      id: id,
      userId: measurement.userId,
      measurementDate: measurement.measurementDate,
      weight: measurement.weight,
      height: measurement.height,
      bodyFatPercentage: measurement.bodyFatPercentage,
      muscleMass: measurement.muscleMass,
      bmi: measurement.bmi,
      chest: measurement.chest,
      waist: measurement.waist,
      hips: measurement.hips,
      biceps: measurement.biceps,
      thighs: measurement.thighs,
      calves: measurement.calves,
      photoPath: measurement.photoPath,
      notes: measurement.notes,
      createdAt: measurement.createdAt,
    );
  }

  Future<List<BodyMeasurements>> getBodyMeasurementsByUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'body_measurements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'measurement_date DESC',
    );
    return result.map((map) => BodyMeasurements.fromMap(map)).toList();
  }

  Future<BodyMeasurements?> getLatestBodyMeasurement(int userId) async {
    final db = await database;
    final result = await db.query(
      'body_measurements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'measurement_date DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return BodyMeasurements.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateBodyMeasurement(BodyMeasurements measurement) async {
    final db = await database;
    return await db.update(
      'body_measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  Future<int> deleteBodyMeasurement(int id) async {
    final db = await database;
    return await db.delete(
      'body_measurements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== USER_GOALS OPERATIONS ====================
  Future<UserGoals> createUserGoal(UserGoals goal) async {
    final db = await database;
    final id = await db.insert('user_goals', goal.toMap());
    return UserGoals(
      id: id,
      userId: goal.userId,
      goalType: goal.goalType,
      targetMetric: goal.targetMetric,
      currentValue: goal.currentValue,
      targetValue: goal.targetValue,
      targetDate: goal.targetDate,
      description: goal.description,
      status: goal.status,
      progress: goal.progress,
      createdAt: goal.createdAt,
      completedAt: goal.completedAt,
    );
  }

  Future<List<UserGoals>> getActiveGoalsByUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'user_goals',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'active'],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => UserGoals.fromMap(map)).toList();
  }

  Future<List<UserGoals>> getAllGoalsByUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'user_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => UserGoals.fromMap(map)).toList();
  }

  Future<int> updateUserGoal(UserGoals goal) async {
    final db = await database;
    return await db.update(
      'user_goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteUserGoal(int id) async {
    final db = await database;
    return await db.delete('user_goals', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== EXERCISE_IMAGES OPERATIONS ====================
  Future<ExerciseImages> createExerciseImage(ExerciseImages image) async {
    final db = await database;
    final id = await db.insert('exercise_images', image.toMap());
    return ExerciseImages(
      id: id,
      exerciseId: image.exerciseId,
      imageUrl: image.imageUrl,
      imageType: image.imageType,
      orderIndex: image.orderIndex,
      caption: image.caption,
      isPrimary: image.isPrimary,
      createdAt: image.createdAt,
    );
  }

  Future<List<ExerciseImages>> getImagesByExercise(int exerciseId) async {
    final db = await database;
    final result = await db.query(
      'exercise_images',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'order_index ASC',
    );
    return result.map((map) => ExerciseImages.fromMap(map)).toList();
  }

  Future<ExerciseImages?> getPrimaryImageByExercise(int exerciseId) async {
    final db = await database;
    final result = await db.query(
      'exercise_images',
      where: 'exercise_id = ? AND is_primary = 1',
      whereArgs: [exerciseId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return ExerciseImages.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateExerciseImage(ExerciseImages image) async {
    final db = await database;
    return await db.update(
      'exercise_images',
      image.toMap(),
      where: 'id = ?',
      whereArgs: [image.id],
    );
  }

  Future<int> deleteExerciseImage(int id) async {
    final db = await database;
    return await db.delete('exercise_images', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== HYDRATION_LOGS OPERATIONS ====================
  Future<HydrationLog> createHydrationLog(HydrationLog log) async {
    final db = await database;
    final id = await db.insert('hydration_logs', log.toMap());
    return HydrationLog(
      id: id,
      userId: log.userId,
      amountMl: log.amountMl,
      date: log.date,
    );
  }

  // ==================== USER_BADGES OPERATIONS ====================
  Future<UserBadge> createUserBadge(UserBadge badge) async {
    final db = await database;
    final id = await db.insert('user_badges', badge.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    return UserBadge(
      id: id == 0 ? badge.id : id,
      userId: badge.userId,
      badgeCode: badge.badgeCode,
      title: badge.title,
      description: badge.description,
      earnedAt: badge.earnedAt,
    );
  }

  Future<bool> hasUserBadge(int userId, String badgeCode) async {
    final db = await database;
    final result = await db.query(
      'user_badges',
      columns: ['id'],
      where: 'user_id = ? AND badge_code = ?',
      whereArgs: [userId, badgeCode],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<UserBadge>> getUserBadges(int userId) async {
    final db = await database;
    final result = await db.query(
      'user_badges',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'earned_at DESC',
    );
    return result.map((map) => UserBadge.fromMap(map)).toList();
  }

  Future<int> getTodayHydration(int userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount_ml) as total
      FROM hydration_logs
      WHERE user_id = ? AND date = ?
    ''',
      [userId, today],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  Future<List<HydrationLog>> getHydrationLogsByDate(
    int userId,
    DateTime date,
  ) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final result = await db.query(
      'hydration_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, dateStr],
      orderBy: 'id DESC',
    );
    return result.map((map) => HydrationLog.fromMap(map)).toList();
  }

  Future<bool> hasWorkoutToday(int userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM workout_sessions
      WHERE user_id = ? AND DATE(start_time) = ?
    ''',
      [userId, today],
    );

    return ((result.first['count'] as int?) ?? 0) > 0;
  }

  Future<int> updateHydrationLog(HydrationLog log) async {
    final db = await database;
    return await db.update(
      'hydration_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteHydrationLog(int id) async {
    final db = await database;
    return await db.delete('hydration_logs', where: 'id = ?', whereArgs: [id]);
  }

  // Subscription operations
  Future<Subscription?> getActiveSubscription(int userId) async {
    final db = await database;
    final result = await db.query(
      'subscriptions',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'end_date DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Subscription.fromMap(result.first);
    }
    return null;
  }

  // Appointment operations
  Future<List<Appointment>> getAppointmentsByUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'appointments',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'appointment_date DESC',
    );
    return result.map((map) => Appointment.fromMap(map)).toList();
  }

  // Group Class operations
  Future<List<GroupClass>> getGroupClassesByBranch(int branchId) async {
    final db = await database;
    final result = await db.query(
      'group_classes',
      where: 'gym_branch_id = ? AND is_active = 1',
      whereArgs: [branchId],
    );
    return result.map((map) => GroupClass.fromMap(map)).toList();
  }

  // Diet Plan operations
  Future<List<DietPlan>> getAllDietPlans() async {
    final db = await database;
    final result = await db.query(
      'diet_plans',
      where: 'is_active = 1',
      orderBy: 'name',
    );
    return result.map((map) => DietPlan.fromMap(map)).toList();
  }

  Future<UserDiet?> getCurrentUserDiet(int userId) async {
    final db = await database;
    final result = await db.query(
      'user_diet',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return UserDiet.fromMap(result.first);
    }
    return null;
  }

  Future<void> createOrUpdateUserDiet(UserDiet userDiet) async {
    final db = await database;
    
    // Deactivate all previous diets for this user
    await db.update(
      'user_diet',
      {'is_active': 0},
      where: 'user_id = ?',
      whereArgs: [userDiet.userId],
    );
    
    // Insert new diet
    await db.insert('user_diet', userDiet.toMap());
  }

  // Trainer operations
  Future<List<Trainer>> getTrainersByBranch(int branchId) async {
    final db = await database;
    final result = await db.query(
      'trainers',
      where: 'gym_branch_id = ? AND is_active = 1',
      whereArgs: [branchId],
      orderBy: 'name',
    );
    return result.map((map) => Trainer.fromMap(map)).toList();
  }
}

// Extension methods for copyWith
extension UserCopyWith on User {
  User copyWith({int? id, String? name, String? email, DateTime? createdAt}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension ExerciseCopyWith on Exercise {
  Exercise copyWith({
    int? id,
    String? name,
    String? description,
    String? muscleGroup,
    String? equipment,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension WorkoutSessionCopyWith on WorkoutSession {
  WorkoutSession copyWith({
    int? id,
    int? userId,
    DateTime? startTime,
    DateTime? endTime,
    String? sessionType,
    int? totalDuration,
    DateTime? createdAt,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sessionType: sessionType ?? this.sessionType,
      totalDuration: totalDuration ?? this.totalDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension ExerciseLogCopyWith on ExerciseLog {
  ExerciseLog copyWith({
    int? id,
    int? workoutSessionId,
    int? exerciseId,
    int? orderInSession,
    DateTime? createdAt,
  }) {
    return ExerciseLog(
      id: id ?? this.id,
      workoutSessionId: workoutSessionId ?? this.workoutSessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderInSession: orderInSession ?? this.orderInSession,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension SetDetailsCopyWith on SetDetails {
  SetDetails copyWith({
    int? id,
    int? exerciseLogId,
    int? setNumber,
    double? weight,
    int? reps,
    DateTime? createdAt,
  }) {
    return SetDetails(
      id: id ?? this.id,
      exerciseLogId: exerciseLogId ?? this.exerciseLogId,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension GymBranchCopyWith on GymBranch {
  GymBranch copyWith({
    int? id,
    String? name,
    String? address,
    String? city,
    String? phone,
    String? email,
    double? latitude,
    double? longitude,
    String? openingTime,
    String? closingTime,
    String? facilities,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return GymBranch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      facilities: facilities ?? this.facilities,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension EquipmentCopyWith on Equipment {
  Equipment copyWith({
    int? id,
    int? gymBranchId,
    String? name,
    String? type,
    String? brand,
    String? model,
    String? qrCode,
    String? description,
    bool? isAvailable,
    DateTime? lastMaintenanceDate,
    DateTime? createdAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      gymBranchId: gymBranchId ?? this.gymBranchId,
      name: name ?? this.name,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      qrCode: qrCode ?? this.qrCode,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension BodyMeasurementsCopyWith on BodyMeasurements {
  BodyMeasurements copyWith({
    int? id,
    int? userId,
    DateTime? measurementDate,
    double? weight,
    double? height,
    double? bodyFatPercentage,
    double? muscleMass,
    double? bmi,
    double? chest,
    double? waist,
    double? hips,
    double? biceps,
    double? thighs,
    double? calves,
    String? notes,
    DateTime? createdAt,
  }) {
    return BodyMeasurements(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      measurementDate: measurementDate ?? this.measurementDate,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      muscleMass: muscleMass ?? this.muscleMass,
      bmi: bmi ?? this.bmi,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      biceps: biceps ?? this.biceps,
      thighs: thighs ?? this.thighs,
      calves: calves ?? this.calves,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

extension UserGoalsCopyWith on UserGoals {
  UserGoals copyWith({
    int? id,
    int? userId,
    String? goalType,
    String? targetMetric,
    double? currentValue,
    double? targetValue,
    DateTime? targetDate,
    String? description,
    String? status,
    double? progress,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return UserGoals(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      targetMetric: targetMetric ?? this.targetMetric,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      targetDate: targetDate ?? this.targetDate,
      description: description ?? this.description,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

extension ExerciseImagesCopyWith on ExerciseImages {
  ExerciseImages copyWith({
    int? id,
    int? exerciseId,
    String? imageUrl,
    String? imageType,
    int? orderIndex,
    String? caption,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return ExerciseImages(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      imageUrl: imageUrl ?? this.imageUrl,
      imageType: imageType ?? this.imageType,
      orderIndex: orderIndex ?? this.orderIndex,
      caption: caption ?? this.caption,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
