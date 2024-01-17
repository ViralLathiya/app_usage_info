import 'package:app_usage/app_usage.dart';
import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:device_apps/device_apps.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppUsageScreen(),
    );
  }
}

class AppUsageData {
  final String appName;
  final String packageName;
  final DateTime? usage;
  final String? appIconPath;

  final String firstTimeStamp;
  final String lastTimeUsed;
  final String totalTimeInForeground;

  AppUsageData({
    required this.appName,
    required this.packageName,
    required this.usage,
    required this.appIconPath,
    required this.firstTimeStamp,
    required this.lastTimeUsed,
    required this.totalTimeInForeground,
  });
}

class AppUsageScreen extends StatefulWidget {
  @override
  _AppUsageScreenState createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> {
  List<AppUsageData> _appUsageList = [];

  List<AppUsageData> _systemAppList = [];

  @override
  void initState() {
    super.initState();
    _getAppUsageData();
  }

  Future<void> _getAppUsageData() async {
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(const Duration(days: 7)); // Example: Last 7 days

    List<AppUsageInfo> _ = await AppUsage().getAppUsage(startDate, endDate);

    List<UsageInfo> usageInfoList = await UsageStats.queryUsageStats(startDate, endDate);

    for (var info in usageInfoList) {
      try {
        List<Application> visibleApps = await DeviceApps.getInstalledApplications(
          includeSystemApps: true,
          onlyAppsWithLaunchIntent: true,
          includeAppIcons: true,
        );

        for (var element in visibleApps) {
          if (info.packageName == element.packageName) {
            DateTime? lastTimeUsed = info.totalTimeInForeground != null
                ? DateTime.fromMillisecondsSinceEpoch(int.parse(info.totalTimeInForeground!))
                : null;

            final obj = AppUsageData(
              appName: element.appName,
              packageName: info.packageName!,
              usage: lastTimeUsed,
              appIconPath: element.apkFilePath,
              firstTimeStamp: info.firstTimeStamp ?? '',
              totalTimeInForeground: info.totalTimeInForeground ?? '',
              lastTimeUsed: info.lastTimeUsed ?? '',
            );

            if (element.systemApp) {
              _systemAppList.add(obj);
            } else {
              _appUsageList.add(obj);
            }
          }
        }
      } catch (e) {
        print('Error getting app info: $e');
      }
    }

    setState(() {
      _appUsageList = _appUsageList;
    });
  }

  String _formatDateTime(String? timestamp) {
    if (timestamp == null) return 'N/A';

    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return timeago.format(dateTime, locale: 'en');
  }

  String _formatDuration1(String? durationMillis) {
    if (durationMillis == null) return 'N/A';

    int durationInMilliseconds = int.parse(durationMillis);
    Duration duration = Duration(milliseconds: durationInMilliseconds);

    return timeago.format(DateTime.now().subtract(duration), locale: 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage Stats'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: const BoxDecoration(color: Colors.grey),
              child: const Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("User Install Apps"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              itemCount: _appUsageList.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final info = _appUsageList[index];
                return ListTile(
                  title: Text(info.packageName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('First Time Used: ${_formatDateTime(info.firstTimeStamp)}'),
                      Text('Last Time Used: ${_formatDateTime(info.lastTimeUsed)}'),
                      Text('Usage Time: ${_formatDuration1(info.totalTimeInForeground)}'),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Container(
              decoration: const BoxDecoration(color: Colors.grey),
              child: const Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("System Apps"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              itemCount: _systemAppList.length,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final info = _systemAppList[index];
                return ListTile(
                  title: Text(info.packageName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('First Time Used: ${_formatDateTime(info.firstTimeStamp)}'),
                      Text('Last Time Used: ${_formatDateTime(info.lastTimeUsed)}'),
                      Text('Usage Time: ${_formatDuration1(info.totalTimeInForeground)}'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
