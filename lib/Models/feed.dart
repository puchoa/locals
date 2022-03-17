import 'dart:convert';

Feed feedFromJson(String str) => Feed.fromJson(json.decode(str));

class Feed {
  Feed({required this.status, required this.code, required this.data});

  int status;
  String code;
  final List<Data> data;

  factory Feed.fromJson(Map<String, dynamic> json) => Feed(
      status: json['status'],
      code: json['code'],
      data: json["data"] != null ? List<Data>.from(json["data"].map((x) => Data.fromJson(x))) : []);
}

class Data {
  Data({
    required this.id,
    required this.authorId,
    required this.communityId,
    required this.text,
    required this.title,
    required this.likedByUs,
    required this.commentedByUs,
    required this.bookmarked,
    required this.timestamp,
    required this.totalPostViews,
    required this.isBlured,
    required this.authorName,
    required this.authorAvatarExtension,
    required this.authorAvatarUrl,
  });

  int id;
  int authorId;
  int communityId;
  String text;
  String title;
  bool likedByUs;
  bool commentedByUs;
  bool bookmarked;
  int timestamp;
  int totalPostViews;
  bool isBlured;
  String authorName;
  String authorAvatarExtension;
  String authorAvatarUrl;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        authorId: json["author_id"],
        communityId: json["community_id"],
        text: json["text"],
        title: json["title"],
        likedByUs: json["liked_by_us"],
        commentedByUs: json["commented_by_us"],
        bookmarked: json["bookmarked"],
        timestamp: json["timestamp"],
        totalPostViews: json["total_post_views"],
        isBlured: json["is_blured"],
        authorName: json["author_name"],
        authorAvatarExtension: json["author_avatar_extension"],
        authorAvatarUrl: json["author_avatar_url"],
      );
}
