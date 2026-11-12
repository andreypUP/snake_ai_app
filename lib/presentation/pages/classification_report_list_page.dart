import 'dart:io';
import 'package:flutter/material.dart';
import 'package:venom_shield_ph/core/di/injection_container.dart';
import 'package:venom_shield_ph/core/network/network_info.dart';
import 'package:venom_shield_ph/domain/models/classification_report.dart';
import 'package:venom_shield_ph/domain/services/auth_service.dart';
import 'package:venom_shield_ph/domain/services/classification_db_service.dart';
import 'package:venom_shield_ph/domain/services/classification_sync_service.dart';
import 'package:venom_shield_ph/routes.dart';

class ClassificationReportListPage extends StatefulWidget {
  const ClassificationReportListPage({super.key});

  @override
  State<ClassificationReportListPage> createState() => _ClassificationReportListPageState();
}

class _ClassificationReportListPageState extends State<ClassificationReportListPage> {
  final ClassificationDbService _dbService = getIt<ClassificationDbService>();
  final AuthService _authService = getIt<AuthService>();
  final ClassificationSyncService _syncService = getIt<ClassificationSyncService>();
  final NetworkInfo _networkInfo = getIt<NetworkInfo>();

  List<ClassificationReport> _reports = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
    _checkConnection();
  }



  Future<void> _checkConnection() async {
    final connected = await _networkInfo.isConnected;
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid ?? '';
      if (userId.isNotEmpty) {
        final reports = await _dbService.getClassificationReportsByUser(userId);
        if (mounted) {
          setState(() {
            _reports = reports;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  Future<void> _syncReports() async {
    final connected = await _networkInfo.isConnected;
    if (!connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    int syncedCount = 0;
    int failedCount = 0;

    try {
      final userId = _authService.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      final unsyncedReports = await _dbService.getUnsyncedReports(userId);

      for (var report in unsyncedReports) {
        try {
          // Upload to Firestore and Firebase Storage
          final imageFile = File(report.imageLocalPath);
          if (await imageFile.exists()) {
            // Get the image URL from the sync service
            final imageUrl = await _syncService.syncClassificationReport(report, imageFile);

            // Mark as synced in local DB with the returned image URL
            await _dbService.markAsSynced(report.id, imageUrl);

            syncedCount++;
          } else {
            debugPrint('Image file not found: ${report.imageLocalPath}');
            failedCount++;
          }
        } catch (e) {
          // Continue with other reports even if one fails
          debugPrint('Failed to sync report ${report.id}: $e');
          failedCount++;
        }
      }

      if (mounted) {
        if (syncedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Synced $syncedCount report(s) successfully${failedCount > 0 ? ', $failedCount failed' : ''}'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (failedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sync $failedCount report(s)'),
              backgroundColor: Colors.red,
            ),
          );
        }
        await _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unsyncedCount = _reports.where((r) => !r.isSynced).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classification History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isConnected && unsyncedCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: _syncReports,
                        icon: const Icon(Icons.cloud_upload, color: Colors.white),
                        label: Text(
                          'Sync ($unsyncedCount)',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 100,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No classifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start using the AI Cam to classify snakes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  color: Colors.green,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      return _buildReportCard(report);
                    },
                  ),
                ),
    );
  }

  Widget _buildReportCard(ClassificationReport report) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          ClassificationReportDetailPageRoute(reportId: report.id).push(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(report.imageLocalPath),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Report details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.snakeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (report.scientificName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        report.scientificName!,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.percent,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(report.confidence * 100).toStringAsFixed(1)}% confidence',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(report.dateClassified),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Sync status indicator
              Icon(
                report.isSynced ? Icons.cloud_done : Icons.cloud_off,
                color: report.isSynced ? Colors.green : Colors.orange,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
