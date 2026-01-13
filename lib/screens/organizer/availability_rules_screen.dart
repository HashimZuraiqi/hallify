import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/hall_model.dart';
import '../../models/availability_rule_model.dart';
import '../../providers/availability_provider.dart';

/// Premium availability rules editor for organizers.
/// Allows setting weekly schedule and specific date overrides.
class AvailabilityRulesScreen extends StatefulWidget {
  final HallModel hall;

  const AvailabilityRulesScreen({super.key, required this.hall});

  @override
  State<AvailabilityRulesScreen> createState() => _AvailabilityRulesScreenState();
}

class _AvailabilityRulesScreenState extends State<AvailabilityRulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Start listening to rules
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AvailabilityProvider>(context, listen: false);
      provider.startListeningToRules(widget.hall.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    final provider = Provider.of<AvailabilityProvider>(context, listen: false);
    provider.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Availability',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            Text(
              widget.hall.name,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          // Quick setup button
          Consumer<AvailabilityProvider>(
            builder: (context, provider, _) {
              final hasRules = provider.weeklyRules.isNotEmpty;
              if (hasRules) return const SizedBox.shrink();
              
              return TextButton.icon(
                onPressed: () => _showQuickSetupDialog(),
                icon: const Icon(Icons.flash_on, size: 18),
                label: const Text('Quick Setup'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              indicatorColor: AppTheme.primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Weekly Hours'),
                Tab(text: 'Date Overrides'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WeeklyHoursTab(hallId: widget.hall.id),
          _DateOverridesTab(hallId: widget.hall.id),
        ],
      ),
    );
  }

  void _showQuickSetupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quick Setup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will create a default weekly schedule:'),
            const SizedBox(height: 16),
            _QuickSetupItem(icon: Icons.calendar_today, text: 'Monday - Friday'),
            _QuickSetupItem(icon: Icons.access_time, text: '9:00 AM - 6:00 PM'),
            _QuickSetupItem(icon: Icons.timelapse, text: '1-hour slots'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<AvailabilityProvider>(context, listen: false);
              final success = await provider.createDefaultRules(venueId: widget.hall.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Weekly schedule created!' : 'Failed to create schedule'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Schedule'),
          ),
        ],
      ),
    );
  }
}

class _QuickSetupItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _QuickSetupItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

/// Weekly hours tab
class _WeeklyHoursTab extends StatelessWidget {
  final String hallId;

  const _WeeklyHoursTab({required this.hallId});

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AvailabilityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.rules.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final weeklyRules = provider.weeklyRules;

        if (weeklyRules.isEmpty) {
          return _EmptyWeeklyState(hallId: hallId);
        }

        // Group rules by weekday
        final rulesByDay = <int, AvailabilityRuleModel>{};
        for (final rule in weeklyRules) {
          if (rule.weekday != null) {
            rulesByDay[rule.weekday!] = rule;
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 7,
          itemBuilder: (context, index) {
            final weekday = index + 1; // 1 = Monday
            final rule = rulesByDay[weekday];
            
            return _WeekdayCard(
              hallId: hallId,
              weekday: weekday,
              weekdayName: _weekdays[index],
              rule: rule,
            );
          },
        );
      },
    );
  }
}

/// Empty state for weekly hours
class _EmptyWeeklyState extends StatelessWidget {
  final String hallId;

  const _EmptyWeeklyState({required this.hallId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Weekly Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your regular business hours so customers\nknow when your venue is available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _addWeekdayRule(context),
              icon: const Icon(Icons.add),
              label: const Text('Add First Day'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addWeekdayRule(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddWeekdaySheet(hallId: hallId),
    );
  }
}

/// Card for each weekday
class _WeekdayCard extends StatelessWidget {
  final String hallId;
  final int weekday;
  final String weekdayName;
  final AvailabilityRuleModel? rule;

  const _WeekdayCard({
    required this.hallId,
    required this.weekday,
    required this.weekdayName,
    this.rule,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = rule != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isEnabled ? AppTheme.primaryColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              weekdayName.substring(0, 3).toUpperCase(),
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.grey[500],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        title: Text(
          weekdayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isEnabled
              ? '${rule!.startTime} - ${rule!.endTime} (${rule!.slotDurationMinutes}min slots)'
              : 'Not available',
          style: TextStyle(
            color: isEnabled ? Colors.grey[700] : Colors.grey[500],
            fontSize: 13,
          ),
        ),
        trailing: Switch(
          value: isEnabled,
          activeColor: AppTheme.primaryColor,
          onChanged: (value) => _toggleDay(context, value),
        ),
        onTap: isEnabled ? () => _editRule(context) : () => _addRule(context),
      ),
    );
  }

  void _toggleDay(BuildContext context, bool enable) async {
    final provider = Provider.of<AvailabilityProvider>(context, listen: false);
    
    if (enable) {
      // Add default hours
      await provider.createWeeklyRule(
        venueId: hallId,
        weekday: weekday,
        startTime: '09:00',
        endTime: '18:00',
      );
    } else {
      // Remove
      if (rule != null) {
        await provider.deleteRule(rule!.id);
      }
    }
  }

  void _addRule(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddWeekdaySheet(
        hallId: hallId,
        preselectedWeekday: weekday,
      ),
    );
  }

  void _editRule(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditRuleSheet(rule: rule!),
    );
  }
}

/// Bottom sheet for adding weekday rules
class _AddWeekdaySheet extends StatefulWidget {
  final String hallId;
  final int? preselectedWeekday;

  const _AddWeekdaySheet({required this.hallId, this.preselectedWeekday});

  @override
  State<_AddWeekdaySheet> createState() => _AddWeekdaySheetState();
}

class _AddWeekdaySheetState extends State<_AddWeekdaySheet> {
  int? _selectedWeekday;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  int _slotDuration = 60;
  bool _isLoading = false;

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _selectedWeekday = widget.preselectedWeekday;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Weekly Hours',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Weekday selector
          if (widget.preselectedWeekday == null) ...[
            const Text('Day', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final weekday = index + 1;
                final isSelected = _selectedWeekday == weekday;
                return ChoiceChip(
                  label: Text(_weekdays[index].substring(0, 3)),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    setState(() => _selectedWeekday = selected ? weekday : null);
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
          
          // Time pickers
          Row(
            children: [
              Expanded(
                child: _TimePicker(
                  label: 'Start Time',
                  time: _startTime,
                  onChanged: (time) => setState(() => _startTime = time),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimePicker(
                  label: 'End Time',
                  time: _endTime,
                  onChanged: (time) => setState(() => _endTime = time),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Slot duration
          const Text('Slot Duration', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [30, 60, 90, 120].map((mins) {
              final isSelected = _slotDuration == mins;
              return ChoiceChip(
                label: Text(mins < 60 ? '${mins}m' : '${mins ~/ 60}h'),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _slotDuration = mins);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          
          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedWeekday != null && !_isLoading ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    
    final provider = Provider.of<AvailabilityProvider>(context, listen: false);
    final success = await provider.createWeeklyRule(
      venueId: widget.hallId,
      weekday: _selectedWeekday!,
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      slotDuration: _slotDuration,
    );

    if (mounted) {
      Navigator.pop(context);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Time picker widget
class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final result = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (result != null) onChanged(result);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
                Icon(Icons.access_time, color: Colors.grey[500], size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Edit rule bottom sheet
class _EditRuleSheet extends StatelessWidget {
  final AvailabilityRuleModel rule;

  const _EditRuleSheet({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.access_time, color: AppTheme.primaryColor),
            title: const Text('Current Hours'),
            subtitle: Text('${rule.startTime} - ${rule.endTime}'),
          ),
          ListTile(
            leading: const Icon(Icons.timelapse, color: AppTheme.primaryColor),
            title: const Text('Slot Duration'),
            subtitle: Text('${rule.slotDurationMinutes} minutes'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Remove This Day', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final provider = Provider.of<AvailabilityProvider>(context, listen: false);
              await provider.deleteRule(rule.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/// Date overrides tab
class _DateOverridesTab extends StatelessWidget {
  final String hallId;

  const _DateOverridesTab({required this.hallId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AvailabilityProvider>(
      builder: (context, provider, _) {
        final overrides = provider.specificDateRules;
        
        return Column(
          children: [
            // Add button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addOverride(context),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Date Override'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _blockDate(context),
                      icon: const Icon(Icons.block),
                      label: const Text('Block a Date'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // List
            Expanded(
              child: overrides.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No date overrides',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add special hours or block specific dates',
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: overrides.length,
                      itemBuilder: (context, index) {
                        return _OverrideCard(rule: overrides[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _addOverride(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddOverrideSheet(hallId: hallId, isBlock: false),
    );
  }

  void _blockDate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddOverrideSheet(hallId: hallId, isBlock: true),
    );
  }
}

/// Override card
class _OverrideCard extends StatelessWidget {
  final AvailabilityRuleModel rule;

  const _OverrideCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    final isBlocked = rule.isBlocked;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.red[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBlocked ? Colors.red[200]! : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isBlocked ? Colors.red : AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isBlocked ? Icons.block : Icons.event_available,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          rule.date != null ? DateFormat('EEEE, MMMM d').format(rule.date!) : 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isBlocked ? 'Blocked - No bookings' : '${rule.startTime} - ${rule.endTime}',
          style: TextStyle(
            color: isBlocked ? Colors.red[700] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final provider = Provider.of<AvailabilityProvider>(context, listen: false);
            await provider.deleteRule(rule.id);
          },
        ),
      ),
    );
  }
}

/// Add override sheet
class _AddOverrideSheet extends StatefulWidget {
  final String hallId;
  final bool isBlock;

  const _AddOverrideSheet({required this.hallId, required this.isBlock});

  @override
  State<_AddOverrideSheet> createState() => _AddOverrideSheetState();
}

class _AddOverrideSheetState extends State<_AddOverrideSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isBlock ? 'Block a Date' : 'Add Special Hours',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isBlock
                ? 'Select a date to block all bookings'
                : 'Override your regular hours for a specific date',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          // Date picker
          GestureDetector(
            onTap: () async {
              final result = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (result != null) setState(() => _selectedDate = result);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          // Time pickers (only for non-block)
          if (!widget.isBlock) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Start Time',
                    time: _startTime,
                    onChanged: (time) => setState(() => _startTime = time),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimePicker(
                    label: 'End Time',
                    time: _endTime,
                    onChanged: (time) => setState(() => _endTime = time),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: !_isLoading ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isBlock ? Colors.red : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      widget.isBlock ? 'Block This Date' : 'Save Override',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    
    final provider = Provider.of<AvailabilityProvider>(context, listen: false);
    
    bool success;
    if (widget.isBlock) {
      success = await provider.blockDate(venueId: widget.hallId, date: _selectedDate);
    } else {
      success = await provider.createSpecificDateRule(
        venueId: widget.hallId,
        date: _selectedDate,
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
      );
    }

    if (mounted) {
      Navigator.pop(context);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
