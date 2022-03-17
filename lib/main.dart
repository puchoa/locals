import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:locals/Models/user.dart';
import 'package:locals/Models/feed.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final url = 'https://app-test.rr-qa.seasteaddigital.com/';
  final email = 'testlocals0@gmail.com';
  final password = 'jahubhsgvd23';
  final deviceId = '7789e3ef-c87f-49c5-a2d3-5165927298f0';

  late User _user;
  Feed? _feed;

  bool isLoading = true, loadingMore = false;

  List<String> order = ["Recent", "Oldest"];
  String dropDownValue = "Recent";

  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _streamSubscription;
  final ScrollController _scrollController = ScrollController();

  Future<void> initConnectivity() async {
    late ConnectivityResult result;

    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      log(e.toString());
      return;
    }
    if (!mounted) {
      return Future.value(null);
    }
    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectivityResult = result;

      if (_connectivityResult != ConnectivityResult.none && _feed == null) {
        fetchUser();
      }
    });
  }

  void fetchUser() async {
    try {
      log('Fetching user data', name: 'network');
      var response = await http.post(Uri.parse(url + 'app_api/auth.php'),
          body: {'email': email, 'password': password, 'device_id': deviceId});

      if (response.statusCode == 200) {
        final userdata = userFromJson(response.body);
        log('Recieved user data', name: 'network');
        setState(() {
          _user = userdata;

          fetchFeed();
        });
      }
    } catch (e) {
      log(e.toString(), name: 'network');
    }
  }

  void fetchFeed({int lpid = 0}) async {
    if (_connectivityResult != ConnectivityResult.none) {
      setState(() {
        loadingMore = true;
      });
    }

    try {
      log('Fetching feed data', name: 'network');

      var response = await http.post(
          Uri.parse(url + 'api/v1/posts/feed/global.json'),
          headers: {
            'X-APP-AUTH-TOKEN': _user.result.ssAuthToken,
            'X-DEVICE-ID': deviceId
          },
          body: json.encode({
            "data": {
              "page_size": 10,
              "order": dropDownValue.toLowerCase(),
              "lpid": lpid
            }
          }));

      if (response.statusCode == 200) {
        setState(() {
          final feedData = feedFromJson(response.body);
          if (_feed == null) {
            _feed = feedData;
          } else {
            _feed!.data.addAll(feedData.data);
          }
          log('Recieved feed data', name: 'network');
          isLoading = loadingMore = false;
        });
      }
    } catch (e) {
      log(e.toString(), name: 'network');
    }
  }

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _streamSubscription =
        _connectivity.onConnectivityChanged.listen((_updateConnectionStatus));

    fetchUser();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !isLoading) {
        log('Adding new data', name: 'network');

        fetchFeed(lpid: _feed!.data[_feed!.data.length - 1].id);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription.cancel();
    _scrollController.dispose();
  }

  Widget profileImage(int i) {
    return SizedBox(
      height: 45,
      width: 45,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          CircleAvatar(
              backgroundImage: NetworkImage(_feed!.data[i].authorAvatarUrl),
              onBackgroundImageError: (_, __) {
                log("unable to load image avatar", name: 'userImage');
              }),
          Positioned(
              right: -5,
              bottom: 4,
              child: Container(
                width: 15,
                height: 15,
                child: const Icon(
                  Icons.check_circle,
                  size: 15,
                  color: Color.fromRGBO(67, 118, 187, 1),
                ),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(31, 31, 31, 1)),
              ))
        ],
      ),
    );
  }

  Widget profileHeader(int i) {
    return Container(
      margin: const EdgeInsets.all(15.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(_feed!.data[i].authorName,
                    style: const TextStyle(
                        color: Color.fromRGBO(155, 50, 49, 1), fontSize: 12)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0.0, 0.0, 0.0),
                  child: _feed!.data[i].authorName.isEmpty
                      ? const Text("")
                      : Text('@${_feed!.data[i].authorName}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 0.0),
              child: Text(
                calculateTime(i),
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
          ]),
    );
  }

  Widget liked(int i) {
    return Row(children: <Widget>[
      TextButton.icon(
        icon: Icon(
          Icons.thumb_up,
          color: _feed!.data[i].likedByUs == true
              ? const Color.fromRGBO(176, 54, 52, 1)
              : const Color.fromRGBO(102, 102, 102, 1),
          size: 14,
        ),
        label: Text(_feed!.data[i].totalPostViews.toString(),
            style: const TextStyle(color: Colors.grey)),
        onPressed: () {
          if (_feed!.data[i].likedByUs == true) {
            setState(() {
              _feed!.data[i].likedByUs = false;
              --_feed!.data[i].totalPostViews;
              log("Liked set to ${_feed!.data[i].likedByUs}", name: "btnLiked");
            });
          } else {
            setState(() {
              _feed!.data[i].likedByUs = true;
              ++_feed!.data[i].totalPostViews;
              log("Liked set to ${_feed!.data[i].likedByUs}", name: "btnLiked");
            });
          }
        },
      )
    ]);
  }

  Widget bookmark(int i) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
          child: Transform.rotate(
            angle: 180 * math.pi / 42,
            child: IconButton(
              onPressed: () {
                if (_feed!.data[i].bookmarked == true) {
                  setState(() {
                    _feed!.data[i].bookmarked = false;
                    log("Liked set to ${_feed!.data[i].bookmarked}",
                        name: "btnBookmark");
                  });
                } else {
                  setState(() {
                    _feed!.data[i].bookmarked = true;
                    log("Liked set to ${_feed!.data[i].bookmarked}",
                        name: "btnBookmark");
                  });
                }
              },
              icon: Icon(_feed!.data[i].bookmarked == true
                  ? Icons.push_pin
                  : Icons.push_pin_outlined),
              color: const Color.fromRGBO(176, 54, 52, 1),
              iconSize: 18.0,
            ),
          ),
        )
      ],
    );
  }

  String calculateTime(int i) {
    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    DateTime dataNow = DateTime.now();

    DateTime tsdate =
        DateTime.fromMillisecondsSinceEpoch(_feed!.data[i].timestamp * 1000);

    // Days ago
    if ((dataNow.difference(tsdate).inHours / 24).round() >= 1) {
      return "${months[tsdate.month - 1]} ${tsdate.day}, ${tsdate.year}";
    }

    // Calculate hours ago
    if (dataNow.difference(tsdate).inHours >= 1) {
      if (dataNow.difference(tsdate).inHours > 1) {
        return "${dataNow.difference(tsdate).inHours} hours ago";
      }
      return "${dataNow.difference(tsdate).inHours} hour ago";
    }

    final differenceMinute = (dataNow.difference(tsdate).inMinutes);
    String timeago = "";
    if (dataNow.hour == tsdate.hour) {
      // Calculate minutes ago
      if (dataNow.difference(tsdate).inMinutes > 1) {
        timeago = "minutes ago";
      } else {
        timeago = "minute ago";
      }
      // Calculate Seconds
      if (differenceMinute == 0) {
        if (dataNow.difference(tsdate).inSeconds > 1) {
          timeago = "seconds ago";
        } else {
          timeago = "second ago";
        }
        return "${dataNow.difference(tsdate).inSeconds} $timeago";
      }
    }
    return "$differenceMinute $timeago";
  }

  Widget dropDownMenuWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          "Sort by: ",
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton(
              dropdownColor: const Color.fromRGBO(31, 31, 31, 1),
              value: dropDownValue,
              items: order.map((String order) {
                return DropdownMenuItem(
                  value: order,
                  child: Text(
                    order,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
              style: const TextStyle(color: Colors.blue),
              onChanged: (String? newValue) {
                setState(() {
                  if (_connectivityResult != ConnectivityResult.none) {
                    dropDownValue = newValue!;
                    log("Change Sort to $dropDownValue", name: "btnDropdown");
                    isLoading = true;
                    _feed!.data.clear();
                    fetchFeed();
                  }
                });
              }),
        ),
      ],
    );
  }

  Widget titleBody(int i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 12.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  _feed!.data[i].title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 0.0),
                  child: Text(_feed!.data[i].text,
                      style: const TextStyle(color: Colors.white)),
                )
              ],
            )),
        const Divider(color: Colors.grey)
      ],
    );
  }

  Widget createListView() {
    return ListView.builder(
        controller: _scrollController,
        itemCount: _feed!.data.length,
        itemBuilder: (context, i) {
          return Card(
              color: const Color.fromRGBO(31, 31, 31, 1),
              shape: RoundedRectangleBorder(
                // if you need this
                side: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 0.0, 0.0),
                  child: Row(
                    children: <Widget>[
                      profileImage(i),
                      profileHeader(i),
                      Expanded(child: bookmark(i)),
                    ],
                  ),
                ),
                titleBody(i),
                liked(i),
              ]));
        });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            backgroundColor: Colors.black,
            body: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: SafeArea(
                child: (_connectivityResult == ConnectivityResult.none &&
                        _feed == null)
                    ? Container(
                        alignment: Alignment.center,
                        child: const Text("No Network Connection",
                            style: TextStyle(color: Colors.white)))
                    : isLoading == true
                        ? Container(
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                                color: Colors.blue),
                          )
                        : Column(
                            children: [
                              dropDownMenuWidget(),
                              Expanded(
                                child: Stack(
                                  children: [
                                    createListView(),
                                    if (loadingMore &&
                                        _connectivityResult !=
                                            ConnectionState.none) ...[
                                      Container(
                                        alignment: Alignment.bottomCenter,
                                        child: const Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              0.0, 0.0, 0.0, 15.0),
                                          child: CircularProgressIndicator(
                                              color: Colors.blue),
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
            )));
  }
}
