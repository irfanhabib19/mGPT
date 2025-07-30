import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mgpt/db_helper.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _historyFuture = DBHelper.getHistory();
  }

  Future<void> _deleteHistory(int id) async {
    await DBHelper.deleteHistory(id);
    setState(() {
      _loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History"), centerTitle: true),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No history yet",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final history = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final type = item["type"];
              final prompt = item["prompt"];
              final response = item["response"];
              final id = item["id"];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prompt text
                      Text(
                        "You: $prompt",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Response (text or image)
                      type == "text"
                          ? Text(response, style: const TextStyle(fontSize: 15))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: response,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, _) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, _, __) =>
                                    const Icon(Icons.error, size: 40),
                              ),
                            ),

                      const SizedBox(height: 10),

                      // Delete button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteHistory(id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
