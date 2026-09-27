import 'models/enums.dart';
import 'models/memory.dart';
import 'models/proposal.dart';

/// Prototipteki `seed()` / kurulum akışının Firestore karşılığı.
class SeedData {
  SeedData._();

  static DateTime _daysAgo(int n, {int hour = 20}) {
    final d = DateTime.now().subtract(Duration(days: n));
    return DateTime(d.year, d.month, d.day, hour, 12);
  }

  /// Onboarding sırasında "söylenen" hafızalar.
  static List<Memory> onboardingMemories({
    required String userId,
    required String name,
    required String role,
    required List<String> topics,
    required List<String> goals,
    required List<String> times,
    required String sessionLength,
    required List<String> formats,
  }) {
    final now = DateTime.now();
    const steps = [
      'You chose this during onboarding.',
      'Saved directly — you said it.',
    ];
    String lower(List<String> items) =>
        items.map((e) => e.toLowerCase()).toList().join(', ');

    return [
      Memory(
        userId: userId,
        layer: MemoryLayer.identity,
        statement: 'Your name is $name.',
        source: MemorySource.explicit,
        detail: 'Onboarding',
        derivation: steps,
        confirmedAt: now,
        createdAt: now,
      ),
      Memory(
        userId: userId,
        layer: MemoryLayer.identity,
        statement: 'You work as a ${role.toLowerCase()}.',
        source: MemorySource.explicit,
        detail: 'Onboarding',
        derivation: steps,
        confirmedAt: now,
        createdAt: now,
      ),
      Memory(
        userId: userId,
        layer: MemoryLayer.preference,
        statement: 'Drawn to ${lower(topics)}.',
        source: MemorySource.explicit,
        detail: 'Onboarding',
        derivation: steps,
        confirmedAt: now,
        createdAt: now,
      ),
      Memory(
        userId: userId,
        layer: MemoryLayer.preference,
        statement: 'Goals: ${lower(goals)}.',
        source: MemorySource.explicit,
        detail: 'Onboarding',
        derivation: steps,
        confirmedAt: now,
        createdAt: now,
      ),
      Memory(
        userId: userId,
        layer: MemoryLayer.preference,
        statement: '~$sessionLength-minute sessions, ${lower(times)}.',
        source: MemorySource.explicit,
        detail: 'Onboarding',
        derivation: steps,
        confirmedAt: now,
        createdAt: now,
      ),
      Memory(
        userId: userId,
        layer: MemoryLayer.preference,
        statement: 'Prefers ${lower(formats)}.',
        source: MemorySource.explicit,
        detail: 'Onboarding',
        derivation: steps,
        confirmedAt: now,
        createdAt: now,
      ),
    ];
  }

  /// Bağlantıların ilk kez bağlandığında gördüğün gözlemsel hafızalar.
  static List<Memory> demoMemories(String userId) {
    Memory m({
      required MemoryLayer layer,
      required String statement,
      required MemorySource source,
      String? connection,
      String? detail,
      List<String> derivation = const [],
      double? confidence,
      String? basis,
      required DateTime created,
      bool live = false,
      int expiryDays = 7,
    }) {
      return Memory(
        userId: userId,
        layer: layer,
        statement: statement,
        source: source,
        connection: connection,
        detail: detail,
        derivation: derivation,
        confidence: confidence,
        basis: basis,
        confirmedAt: created,
        createdAt: created,
        expiresAt: live
            ? created.add(Duration(days: expiryDays))
            : null,
      );
    }

    return [
      m(
        layer: MemoryLayer.identity,
        statement: 'Monthly book club with Jonah and Priya.',
        source: MemorySource.explicit,
        detail: 'Tell me, Sep 2',
        derivation: const [
          'You wrote: "I’m in a book club with Jonah and Priya."',
          'Saved directly as a stable fact.',
        ],
        created: _daysAgo(22),
      ),
      m(
        layer: MemoryLayer.preference,
        statement: 'No self-help, please.',
        source: MemorySource.explicit,
        detail: 'Tell me, Jun 30',
        derivation: const [
          'You wrote: "Please don’t suggest self-help books."',
          'Saved directly.',
        ],
        created: _daysAgo(86),
      ),
      m(
        layer: MemoryLayer.preference,
        statement: 'Paper for fiction, digital for nonfiction.',
        source: MemorySource.conversational,
        detail: 'Conversation, Jul 12',
        derivation: const [
          'You said: "I can only read novels on paper."',
          'Umbra proposed it as a preference.',
          'You tapped Keep.',
        ],
        created: _daysAgo(74),
      ),
      m(
        layer: MemoryLayer.pattern,
        statement: 'You read most between 9 and 10:30 pm.',
        source: MemorySource.behavioral,
        detail: 'Session start times',
        derivation: const [
          '19 sessions logged over 12 days.',
          '14 started between 9:00 and 10:30 pm.',
          'You confirmed it recently.',
        ],
        confidence: 0.64,
        basis: '12 days of data',
        created: _daysAgo(10),
      ),
      m(
        layer: MemoryLayer.pattern,
        statement: 'Long books tend to stall mid-way.',
        source: MemorySource.crossapp,
        connection: 'kindle',
        detail: 'Kindle progress',
        derivation: const [
          'Kindle shared 7 books over 400 pages.',
          '5 stopped moving between 40% and 60%.',
          'Small sample, so confidence stays low.',
        ],
        confidence: 0.42,
        basis: '7 books',
        created: _daysAgo(16),
      ),
      m(
        layer: MemoryLayer.pattern,
        statement: 'You highlight passages on memory and attention.',
        source: MemorySource.crossapp,
        connection: 'kindle',
        detail: 'Kindle highlights',
        derivation: const [
          '84 highlights from the last 6 weeks.',
          '51 relate to memory or attention.',
          'You confirmed it recently.',
        ],
        confidence: 0.73,
        basis: '84 highlights',
        created: _daysAgo(13),
      ),
      m(
        layer: MemoryLayer.pattern,
        statement: 'Podcasts fill your Tue/Thu commutes.',
        source: MemorySource.crossapp,
        connection: 'podcasts',
        detail: 'Listening history',
        derivation: const [
          '9 weeks of listening times.',
          'Plays cluster Tue and Thu, 8–9 am.',
          'You confirmed it recently.',
        ],
        confidence: 0.58,
        basis: '9 weeks',
        created: _daysAgo(19),
      ),
      m(
        layer: MemoryLayer.live,
        statement: 'Reading The Extended Mind (62%).',
        source: MemorySource.crossapp,
        connection: 'kindle',
        detail: 'Kindle progress',
        derivation: const [
          'Kindle reported progress yesterday.',
          'You confirmed tracking it.',
        ],
        created: _daysAgo(1),
        live: true,
      ),
      m(
        layer: MemoryLayer.live,
        statement: 'Preparing a talk on attention, Oct 8.',
        source: MemorySource.conversational,
        detail: 'Conversation, Sep 20',
        derivation: const [
          'You said: "I’m giving a talk on attention on the 8th."',
          'You tapped Keep.',
        ],
        created: _daysAgo(4),
        live: true,
      ),
      m(
        layer: MemoryLayer.live,
        statement: 'Book club meets Wed, Sep 30.',
        source: MemorySource.ambient,
        connection: 'calendar',
        detail: 'Calendar event',
        derivation: const [
          'Calendar event "Book club" on Sep 30.',
          'Linked to your book club (Identity).',
          'You tapped Keep.',
        ],
        created: _daysAgo(2),
        live: true,
      ),
    ];
  }

  /// Today'deki "To review" kartları.
  static List<Proposal> proposals() {
    DateTime at(int daysAgo) {
      final d = DateTime.now().subtract(Duration(days: daysAgo));
      return DateTime(d.year, d.month, d.day, 9, 41);
    }

    return [
      Proposal(
        id: 'q_flight',
        layer: MemoryLayer.live,
        statement: 'Saturday flight: ~3 hours offline.',
        prompt: 'A 3-hour flight on Saturday morning is on your calendar.',
        source: MemorySource.ambient,
        connection: 'calendar',
        steps: const ['Calendar event "LHR → LIS", Sat Sep 26, 7:40–10:45.'],
        createdAt: at(1),
      ),
      Proposal(
        id: 'q_econ',
        layer: MemoryLayer.preference,
        statement: 'Economics can wait for now.',
        prompt: 'You skipped 3 economics articles this week.',
        source: MemorySource.behavioral,
        steps: const ['"Not now" on 3 economics articles, Sep 21–23.'],
        createdAt: at(1),
      ),
      Proposal(
        id: 'q_sleep',
        layer: MemoryLayer.pattern,
        statement: 'A growing interest in sleep science.',
        prompt: 'You saved 6 articles about sleep this month.',
        source: MemorySource.crossapp,
        connection: 'readlater',
        confidence: 0.52,
        basis: '6 saves in 3 weeks',
        steps: const ['Read-later shared 6 articles tagged sleep, Sep 3–22.'],
        createdAt: at(2),
      ),
      Proposal(
        id: 'q_library',
        layer: MemoryLayer.pattern,
        statement: 'Saturday mornings may be long-reading time.',
        prompt: 'You opened Umbra at a library three Saturdays running.',
        source: MemorySource.ambient,
        connection: 'location',
        confidence: 0.35,
        basis: '3 Saturdays',
        steps: const [
          'Location: "library" on Sep 5, 12 and 19.',
          'Only the place type is kept.',
        ],
        createdAt: at(3),
      ),
    ];
  }

  static List<(String, String)> logs() => [
        ('Saved what you told me during setup.', 'Today'),
        ('Kindle updated your current book.', 'Yesterday'),
        ('You kept "Preparing a talk on attention".', 'Sep 20'),
        ('You confirmed the evening pattern.', 'Sep 14'),
      ];
}
