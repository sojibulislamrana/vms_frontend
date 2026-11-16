import 'package:flutter/material.dart';

const _ink = Color(0xFF202720);
const _muted = Color(0xFF747B72);
const _paper = Color(0xFFF6F6F1);
const _green = Color(0xFF315E4B);
const _line = Color(0xFFE4E6DE);
final _operationsKey = GlobalKey();
final _workflowKey = GlobalKey();
final _pricingKey = GlobalKey();

/// Public product site with a quiet, editorial tone and clear product entry.
class MarketingHomeScreen extends StatelessWidget {
  const MarketingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Navigation()),
            const SliverToBoxAdapter(child: _Hero()),
            const SliverToBoxAdapter(child: _ProofStrip()),
            SliverToBoxAdapter(child: KeyedSubtree(key: _operationsKey, child: const _OperationsSection())),
            SliverToBoxAdapter(child: KeyedSubtree(key: _workflowKey, child: const _WorkflowSection())),
            SliverToBoxAdapter(child: KeyedSubtree(key: _pricingKey, child: const _PricingSection())),
            const SliverToBoxAdapter(child: _FaqSection()),
            const SliverToBoxAdapter(child: _Footer()),
          ],
        ),
      ),
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Row(
            children: [
              const _Wordmark(),
              const Spacer(),
              if (MediaQuery.sizeOf(context).width > 980) ...[
                _navLink(context, 'Product', _operationsKey),
                _navLink(context, 'How it works', _workflowKey),
                _navLink(context, 'Pricing', _pricingKey),
                const SizedBox(width: 22),
              ],
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: TextButton.styleFrom(foregroundColor: _ink),
                child: const Text('Log in'),
              ),
              const SizedBox(width: 8),
              _DarkButton(
                label: 'Start free',
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navLink(BuildContext context, String label, GlobalKey section) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: TextButton(
          onPressed: () {
            final target = section.currentContext;
            if (target != null) {
              Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
            }
          },
          style: TextButton.styleFrom(foregroundColor: _muted),
          child: Text(label),
        ),
      );
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.route_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          const Text(
            'stark fleet',
            style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          ),
        ],
      );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, wide ? 68 : 34, 28, 72),
          child: wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(flex: 9, child: _heroCopy(context)),
                  const SizedBox(width: 64),
                  const Expanded(flex: 11, child: _ProductPreview()),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _heroCopy(context),
                  const SizedBox(height: 48),
                  const _ProductPreview(),
                ]),
        ),
      ),
    );
  }

  Widget _heroCopy(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEE7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'FLEET OPERATIONS, IN ONE PLACE',
              style: TextStyle(fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: _green),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'A clearer view of every mile.',
            style: TextStyle(
              color: _ink,
              fontSize: MediaQuery.sizeOf(context).width > 700 ? 57 : 43,
              height: 1.02,
              letterSpacing: -2.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Get a clear view of your vehicles and the next step for your team. Stark Fleet keeps the everyday fleet record simple, with a workspace designed to grow as your operation does.',
            style: TextStyle(color: _muted, fontSize: 17, height: 1.65),
          ),
          const SizedBox(height: 28),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _DarkButton(
              label: 'Set up your workspace',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => Navigator.pushNamed(context, '/signup'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login_rounded, size: 17),
              label: const Text('I already have an account'),
              style: TextButton.styleFrom(foregroundColor: _ink, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15)),
            ),
          ]),
          const SizedBox(height: 18),
          const Row(children: [
            Icon(Icons.check_circle_outline, color: _green, size: 16),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'Start with your first fleet. Add your team when you’re ready.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ]),
        ],
      );
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAECE5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE0D6)),
        boxShadow: const [BoxShadow(color: Color(0x100E1A11), blurRadius: 30, offset: Offset(0, 16))],
      ),
      child: Container(
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const _Wordmark(),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE9EDE5), borderRadius: BorderRadius.circular(20)), child: const Text('SAMPLE WORKSPACE', style: TextStyle(color: _green, fontSize: 9, letterSpacing: 0.7, fontWeight: FontWeight.w700))),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(8)),
              child: const Row(children: [Icon(Icons.calendar_today_outlined, size: 13, color: _muted), SizedBox(width: 7), Text('This month', style: TextStyle(fontSize: 11, color: _muted))]),
            ),
          ]),
          const SizedBox(height: 26),
          const Text('Good morning, Sam', style: TextStyle(color: _ink, fontWeight: FontWeight.w600, fontSize: 19, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          const Text('Here’s what needs your attention today.', style: TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, box) {
            final cols = box.maxWidth < 420 ? 2 : 4;
            final data = [
              ('Vehicles', '48', 'In your fleet', Icons.directions_car_outlined),
              ('Active', '39', 'Ready for work', Icons.near_me_outlined),
              ('Maintenance', '3', 'In the workshop', Icons.build_outlined),
              ('Inactive', '6', 'Not in service', Icons.pause_circle_outline),
            ];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: cols == 2 ? 1.75 : 1.15),
              itemBuilder: (context, index) {
                final item = data[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Icon(item.$4, size: 16, color: _green),
                    Text(item.$2, style: const TextStyle(fontSize: 22, color: _ink, fontWeight: FontWeight.w600, height: 1)),
                    Text(item.$1, style: const TextStyle(fontSize: 10, color: _muted)),
                  ]),
                );
              },
            );
          }),
          const SizedBox(height: 20),
          const Text('Fleet status', style: TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          const Text('At a glance, without opening every vehicle record.', style: TextStyle(color: _muted, fontSize: 10)),
          const SizedBox(height: 11),
          const _StatusRow(label: 'Active', count: '39', color: Color(0xFF6F9A78), value: 0.81),
          const _StatusRow(label: 'Maintenance', count: '3', color: Color(0xFFC39148), value: 0.06),
          const _StatusRow(label: 'Inactive', count: '6', color: Color(0xFF9AA197), value: 0.13),
        ]),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.count, required this.color, required this.value});
  final String label;
  final String count;
  final Color color;
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: const TextStyle(color: _muted, fontSize: 11))),
          SizedBox(width: 105, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: value, minHeight: 5, color: color, backgroundColor: _line))),
          const SizedBox(width: 10),
          SizedBox(width: 20, child: Text(count, textAlign: TextAlign.end, style: const TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
      );
}

class _ProofStrip extends StatelessWidget {
  const _ProofStrip();
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: _line))),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 27),
              child: Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 16, children: const [
                Text('BUILT FOR THE PEOPLE WHO KEEP THINGS MOVING', style: TextStyle(color: _muted, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
                _ProofItem(icon: Icons.local_shipping_outlined, text: 'Delivery & logistics'),
                _ProofItem(icon: Icons.handyman_outlined, text: 'Service teams'),
                _ProofItem(icon: Icons.apartment_outlined, text: 'Multi-site operations'),
              ]),
            ),
          ),
        ),
      );
}

class _ProofItem extends StatelessWidget {
  const _ProofItem({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: _green), const SizedBox(width: 8), Text(text, style: const TextStyle(color: _muted, fontSize: 12))]);
}

class _OperationsSection extends StatelessWidget {
  const _OperationsSection();
  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 94, 28, 92),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _Eyebrow('A BETTER WAY TO RUN YOUR FLEET'),
              const SizedBox(height: 17),
              const Text('The details that keep work on track.', style: TextStyle(color: _ink, fontSize: 38, height: 1.1, letterSpacing: -1.4, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              const SizedBox(width: 600, child: Text('No more digging through spreadsheets, inboxes and folders to answer one simple question about a vehicle.', style: TextStyle(color: _muted, fontSize: 16, height: 1.6))),
              const SizedBox(height: 35),
              LayoutBuilder(builder: (context, constraints) {
                final count = constraints.maxWidth < 660 ? 1 : 3;
                final items = [
                  ('01', Icons.directions_car_outlined, 'Know what’s in your fleet', 'Keep each vehicle’s registration, type, make, model and current status in one reliable record.'),
                  ('02', Icons.manage_search_outlined, 'Find the right record quickly', 'Search and narrow your directory by the details your team already knows.'),
                  ('03', Icons.apartment_outlined, 'Give your fleet a home', 'Start with a private workspace for your company, then make room for the tools your team needs next.'),
                ];
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 18, mainAxisSpacing: 18, childAspectRatio: count == 1 ? 2.2 : 0.92),
                  itemBuilder: (context, i) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(15)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Icon(items[i].$2, color: _green, size: 22), const Spacer(), Text(items[i].$1, style: const TextStyle(color: Color(0xFFADB4AA), fontSize: 11, fontWeight: FontWeight.w600))]),
                      const Spacer(),
                      Text(items[i].$3, style: const TextStyle(color: _ink, fontSize: 19, letterSpacing: -0.4, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 9),
                      Text(items[i].$4, style: const TextStyle(color: _muted, fontSize: 13, height: 1.55)),
                    ]),
                  ),
                );
              }),
            ]),
          ),
        ),
      );
}

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFE9EDE5),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 80, 28, 82),
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth > 760;
                final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Eyebrow('MADE FOR REAL OPERATIONS'),
                  const SizedBox(height: 18),
                  const Text('Start with the fleet you have.', style: TextStyle(color: _ink, fontSize: 36, height: 1.12, letterSpacing: -1.2, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 15),
                  const Text('Set up a workspace for your company and add vehicle records as you go. Get started without turning day one into a data project.', style: TextStyle(color: _muted, fontSize: 15, height: 1.6)),
                  const SizedBox(height: 25),
                  const _FeatureLine(title: 'One place for vehicle records', subtitle: 'People can find the same answer, wherever the work happens.'),
                  const _FeatureLine(title: 'A directory built for everyday updates', subtitle: 'Change vehicle details and status as your fleet changes.'),
                  const _FeatureLine(title: 'A workspace that belongs to your company', subtitle: 'Each account sees only the vehicles inside its own workspace.'),
                ]);
                final checklist = Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(color: const Color(0xFFF7F8F3), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFD9E0D4))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('A workday with Stark Fleet', style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    const _TimelineItem(time: '08:15', title: 'Shift starts', note: 'Open the current fleet directory', done: true),
                    const _TimelineItem(time: '10:40', title: 'Vehicle update', note: 'Record a status change', done: false),
                    const _TimelineItem(time: '14:20', title: 'Plan the next step', note: 'Keep the vehicle record current', done: false),
                    const SizedBox(height: 16),
                    Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFE8EEE7), borderRadius: BorderRadius.circular(10)), child: const Row(children: [Icon(Icons.lightbulb_outline, color: _green, size: 18), SizedBox(width: 10), Expanded(child: Text('Small reminders help prevent last-minute scrambles.', style: TextStyle(color: _green, fontSize: 12, height: 1.45, fontWeight: FontWeight.w500)))])),
                  ]),
                );
                return wide ? Row(children: [Expanded(child: text), const SizedBox(width: 72), Expanded(child: checklist)]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 42), checklist]);
              }),
            ),
          ),
        ),
      );
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_rounded, size: 17, color: _green), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12, height: 1.45))]))]));
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.time, required this.title, required this.note, required this.done});
  final String time;
  final String title;
  final String note;
  final bool done;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 50, child: Text(time, style: const TextStyle(color: _muted, fontSize: 11))), Column(children: [Icon(done ? Icons.check_circle : Icons.circle_outlined, color: done ? _green : const Color(0xFFB3BBAF), size: 17), Container(width: 1, height: 35, color: _line)]), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(note, style: const TextStyle(color: _muted, fontSize: 11))]))]));
}

class _PricingSection extends StatelessWidget {
  const _PricingSection();
  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 88, 28, 90),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const _Eyebrow('STRAIGHTFORWARD PLANS'),
              const SizedBox(height: 15),
              const Text('Room to find your rhythm.', textAlign: TextAlign.center, style: TextStyle(color: _ink, fontSize: 36, letterSpacing: -1.2, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Text('Try the workspace with your team. Choose a plan when you’re ready.', style: TextStyle(color: _muted, fontSize: 14)),
              const SizedBox(height: 32),
              LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth > 720;
                final cards = [
                  _PlanCard(name: 'Starter', description: 'A simple start for a small fleet.', price: 'Free', features: const ['Up to 10 vehicles', 'Vehicle records and statuses', 'One private workspace'], button: 'Create a free workspace', onTap: () => Navigator.pushNamed(context, '/signup')),
                  _PlanCard(name: 'Operations', description: 'More room for a growing vehicle list.', price: 'Monthly plan', featured: true, features: const ['Higher vehicle limit', 'Workspace subscription management', 'Stripe hosted test checkout'], button: 'Create your workspace', onTap: () => Navigator.pushNamed(context, '/signup')),
                ];
                return wide ? Row(children: [Expanded(child: cards[0]), const SizedBox(width: 18), Expanded(child: cards[1])]) : Column(children: [cards[0], const SizedBox(height: 16), cards[1]]);
              }),
              const SizedBox(height: 18),
              const Text('Stripe checkout runs in test mode. The workspace owner configures the monthly price in Stripe.', style: TextStyle(color: _muted, fontSize: 11)),
            ]),
          ),
        ),
      );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.name, required this.description, required this.price, required this.features, required this.button, required this.onTap, this.featured = false});
  final String name;
  final String description;
  final String price;
  final List<String> features;
  final String button;
  final VoidCallback onTap;
  final bool featured;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: featured ? const Color(0xFFE8EEE7) : Colors.white, border: Border.all(color: featured ? const Color(0xFFB8C9B8) : _line), borderRadius: BorderRadius.circular(15)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.toUpperCase(), style: const TextStyle(color: _green, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(price, style: const TextStyle(color: _ink, fontSize: 29, letterSpacing: -0.8, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 20),
          for (final feature in features) Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [const Icon(Icons.check, size: 15, color: _green), const SizedBox(width: 9), Text(feature, style: const TextStyle(color: _ink, fontSize: 12))])),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: featured ? _DarkButton(label: button, onPressed: onTap) : OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: _ink, side: const BorderSide(color: _line), padding: const EdgeInsets.symmetric(vertical: 16)), child: Text(button))),
        ]),
      );
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 68, 28, 78),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                _Eyebrow('A FEW THINGS YOU MAY BE WONDERING'),
                SizedBox(height: 14),
                Text('Good to know.', style: TextStyle(color: _ink, fontSize: 34, letterSpacing: -1.1, fontWeight: FontWeight.w600)),
                SizedBox(height: 20),
                _FaqItem(question: 'Can I try Stark Fleet before paying?', answer: 'Yes. Create a workspace and explore the starter experience. The paid plan checkout is set up for Stripe test mode while the product is being prepared.'),
                _FaqItem(question: 'Can I invite people from my team?', answer: 'Team membership is part of the workspace model. Invitations and role management are being built into the product so each company can manage access safely.'),
                _FaqItem(question: 'Do you store vehicle documents?', answer: 'The product is designed around vehicle records and upcoming document dates. File uploads should be enabled only after your workspace storage and retention settings are configured.'),
              ]),
            ),
          ),
        ),
      );
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
  @override
  Widget build(BuildContext context) => ExpansionTile(title: Text(question, style: const TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w600)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18), tilePadding: EdgeInsets.zero, iconColor: _green, collapsedIconColor: _muted, children: [Align(alignment: Alignment.centerLeft, child: Text(answer, style: const TextStyle(color: _muted, fontSize: 13, height: 1.6)))]);
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF222D25),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: Row(children: [
                const Icon(Icons.route_rounded, color: Color(0xFFC7D6C8), size: 19),
                const SizedBox(width: 9),
                const Text('stark fleet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (MediaQuery.sizeOf(context).width > 600) ...[
                  const Text('Fleet operations, made clearer.', style: TextStyle(color: Color(0xFFB9C2B8), fontSize: 12)),
                  const SizedBox(width: 22),
                ],
                TextButton(onPressed: () => Navigator.pushNamed(context, '/login'), child: const Text('Log in', style: TextStyle(color: Color(0xFFCBD4CA)))),
              ]),
            ),
          ),
        ),
      );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: _green, fontSize: 10, letterSpacing: 1.15, fontWeight: FontWeight.w700));
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.label, required this.onPressed, this.icon, this.compact = false});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool compact;
  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20, vertical: compact ? 12 : 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), if (icon != null) ...[const SizedBox(width: 10), Icon(icon, size: 16)]]),
      );
}
