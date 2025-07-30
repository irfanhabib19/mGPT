import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mgpt/feature_box.dart';
import 'package:mgpt/openai_service.dart';
import 'package:mgpt/pallete.dart';
import 'package:mgpt/history_page.dart';
import 'package:mgpt/db_helper.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText _speechToText = SpeechToText();
  String lastWords = '';
  final GroqService _groqService = GroqService();
  FlutterTts flutterTts = FlutterTts();

  String? _responseText; // Groq text reply
  List<String> _imageUrls = []; // StabilityAI image URLs
  bool _isLoading = false;

  int start = 200;
  int delay = 200;

  Future<void> initSpeechToText() async {
    await _speechToText.initialize();
  }

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  Future<void> startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // update when user stops speaking
    if (result.finalResult) {
      setState(() {
        lastWords = result.recognizedWords;
      });
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> systemSpeak(String text) async {
    await flutterTts.stop(); // prevent overlap
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BounceInDown(child: const Text("Emmi")),
        centerTitle: true,
        leading: const Icon(Icons.menu),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Avatar Section ---
            ZoomIn(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      height: 125,
                      width: 125,
                      decoration: BoxDecoration(
                        color: Pallete.assistantCircleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    height: 130,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/virtualAssistant.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Assistant Intro / Response ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              margin: const EdgeInsets.symmetric(
                horizontal: 40,
              ).copyWith(top: 30),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  21,
                ).copyWith(topLeft: Radius.zero),
                border: Border.all(color: Pallete.borderColor),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _responseText == null
                    ? const Text(
                        "Hello, I am Emmi Your Virtual Assistant, How can I help you today ?",
                        key: ValueKey("intro"),
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'Cera Pro',
                          color: Pallete.mainFontColor,
                        ),
                      )
                    : Text(
                        _responseText!,
                        key: ValueKey("response"),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Cera Pro',
                          color: Pallete.mainFontColor,
                        ),
                      ),
              ),
            ),

            // --- Show first generated image ---
            if (_imageUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: CachedNetworkImage(
                    imageUrl: _imageUrls[0],
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error, size: 40),
                  ),
                ),
              ),

            // --- Suggestions ---
            SlideInRight(
              child: Visibility(
                visible:
                    _responseText == null && !_isLoading && _imageUrls.isEmpty,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(top: 7, left: 22),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Here are some suggestions for you",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Cera Pro',
                      color: Pallete.mainFontColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            Visibility(
              visible:
                  _responseText == null && !_isLoading && _imageUrls.isEmpty,
              child: Column(
                children: [
                  SlideInLeft(
                    duration: Duration(milliseconds: start),
                    child: FeatureBox(
                      color: Pallete.firstSuggestionBoxColor,
                      title: "ChatGPT",
                      description:
                          "A smarter way to stay organized and informed with ChatGPT",
                    ),
                  ),
                  SlideInRight(
                    duration: Duration(milliseconds: start + delay),
                    child: FeatureBox(
                      color: Pallete.secondSuggestionBoxColor,
                      title: "Dall-E",
                      description:
                          "Get inspired with Dall-E and create stunning images from text ",
                    ),
                  ),
                  SlideInLeft(
                    duration: Duration(milliseconds: start + delay * 2),
                    child: FeatureBox(
                      color: Pallete.thirdSuggestionBoxColor,
                      title: "Smart Voice Assistant",
                      description:
                          "Gets the best of both worlds with a smart voice assistant ",
                    ),
                  ),
                ],
              ),
            ),

            // --- Response Section ---
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),

            if (_responseText != null && !_isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _responseText!,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),

            if (_imageUrls.isNotEmpty && !_isLoading)
              Column(
                children: _imageUrls.map((url) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      height: 200,
                      placeholder: (context, _) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, _, __) =>
                          const Icon(Icons.error, size: 40),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),

      floatingActionButton: ZoomIn(
        duration: Duration(milliseconds: start + delay * 3),
        child: FloatingActionButton(
          backgroundColor: Pallete.firstSuggestionBoxColor,
          onPressed: () async {
            if (await _speechToText.hasPermission &&
                !_speechToText.isListening) {
              startListening();
            } else if (_speechToText.isListening) {
              setState(() => _isLoading = true);

              final response = await Future.microtask(
                () => _groqService.isArtPromptAPI(lastWords),
              );

              if (response is List<String>) {
                // ✅ Image response
                setState(() {
                  _imageUrls = response as List<String>;
                  _responseText = null;
                  _isLoading = false;
                });

                if (_imageUrls.isNotEmpty) {
                  await DBHelper.insertHistory(
                    lastWords,
                    _imageUrls[0],
                    "image",
                  );
                }
              } else if (response is String) {
                // ✅ Text response
                setState(() {
                  _responseText = response;
                  _imageUrls = [];
                  _isLoading = false;
                });
                await systemSpeak(response);

                await DBHelper.insertHistory(lastWords, response, "text");
              } else {
                setState(() {
                  _responseText = "Sorry, something went wrong.";
                  _imageUrls = [];
                  _isLoading = false;
                });
              }

              await stopListening();
            } else {
              await _speechToText.initialize();
            }
          },
          child: Icon(_speechToText.isListening ? Icons.mic_off : Icons.mic),
        ),
      ),
    );
  }
}
