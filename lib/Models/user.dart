import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

class User {
    User({
       required this.result,
    });

    Result result;

    factory User.fromJson(Map<String, dynamic> json) => User(
        result: Result.fromJson(json["result"]),
    );
}

class Result {
    Result({
         required this.username,
         required this.email,
         required this.userId,
         required this.uniqueId,
         required this.ssAuthToken,
         required this.activeSubscriber,
         required this.unclaimedGift,
    });

    String username;
    String email;
    int userId;
    String uniqueId;
    String ssAuthToken;
    int activeSubscriber;
    int unclaimedGift;

    factory Result.fromJson(Map<String, dynamic> json) => Result(
        username: json["username"],
        email: json["email"],
        userId: json["user_id"],
        uniqueId: json["unique_id"],
        ssAuthToken: json["ss_auth_token"],
        activeSubscriber: json["active_subscriber"],
        unclaimedGift: json["unclaimed_gift"],
    );
}
