import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/romantic_card.dart';
import '../../data/models/message_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/image_cache.dart';
import '../../core/services/image_download.dart';
import '../auth/auth_provider.dart';

bool _isImageUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

void _openImageViewer(BuildContext context, String imageUrl, String messageId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_outlined, color: Colors.white),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (_isImageUrl(imageUrl)) {
                  final bytes = await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl);
                  await downloadImageBytes(bytes.buffer.asUint8List(), 'message_$messageId.jpg');
                } else {
                  await downloadImageBytes(cachedBase64Decode(imageUrl), 'message_$messageId.jpg');
                }
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('បានទាញយករួចរាល់')),
                  );
                }
              },
            ),
          ],
        ),
        body: Center(
          child: _isImageUrl(imageUrl)
              ? PhotoView(imageProvider: NetworkImage(imageUrl))
              : PhotoView(imageProvider: MemoryImage(cachedBase64Decode(imageUrl))),
        ),
      ),
    ),
  );
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ChatRepository _chatRepo = ChatRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FocusNode _inputFocus = FocusNode();
  bool _sendingImage = false;
  String? _partnerImageUrl;
  String? _partnerName;
  StreamSubscription<UserModel?>? _partnerSub;
  String? _editingMessageId;
  MessageModel? _replyingTo;

  // Pagination state
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<MessageModel>>? _messagesSub;
  List<MessageModel> _newestMessages = [];   // real-time (newest ~50)
  List<MessageModel> _olderMessages = [];    // paginated (older pages)
  bool _loadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _paginationCursor;

  // Auto-scroll state
  bool _showNewMessageButton = false;

  @override
  void initState() {
    super.initState();
    NotificationService.clearBadge();
    _watchPartner();
    _initMessages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _partnerSub?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (!pos.hasContentDimensions) return;
    if (pos.pixels >= pos.maxScrollExtent - 300 && !_loadingMore && _hasMore) {
      _loadMoreMessages();
    }
    if (pos.pixels <= 50) {
      if (_showNewMessageButton) {
        setState(() => _showNewMessageButton = false);
      }
    }
  }

  /// Combined message list in descending order (newest first).
  /// Stream messages come first, followed by paginated older messages.
  List<MessageModel> get _allMessages {
    final seen = <String>{};
    return [..._newestMessages, ..._olderMessages].where((m) => seen.add(m.id)).toList();
  }

  void _initMessages() {
    debugPrint('Chat: _initMessages');
    _messagesSub = _chatRepo.messagesStream().listen((messages) {
      if (!mounted) return;
      final wasEmpty = _newestMessages.isEmpty && _olderMessages.isEmpty;
      debugPrint('Chat: stream received ${messages.length} messages');
      setState(() => _newestMessages = messages);
      if (wasEmpty) {
        _scrollToBottom();
      } else if (_scrollController.hasClients) {
        final pos = _scrollController.position;
        if (pos.hasContentDimensions && pos.pixels <= 50) {
          _scrollToBottom();
        } else {
          setState(() => _showNewMessageButton = true);
        }
      }
    }, onError: (e) {
      debugPrint('Chat: stream error: $e');
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    setState(() {});
    if (_paginationCursor == null && _allMessages.isNotEmpty) {
      _paginationCursor = await _chatRepo.getMessageDoc(_allMessages.last.id);
    }
    debugPrint('Chat: _loadMoreMessages cursorDoc=$_paginationCursor');
    try {
      final result = await _chatRepo.loadOlderMessages(cursorDoc: _paginationCursor);
      if (result.messages.isEmpty) {
        _hasMore = false;
        debugPrint('Chat: no more messages');
      } else {
        _olderMessages = [..._olderMessages, ...result.messages];
        _paginationCursor = result.nextCursor;
        if (result.messages.length < ChatRepository.pageSize) _hasMore = false;
        debugPrint('Chat: loaded ${result.messages.length} older messages, total older=${_olderMessages.length}');
      }
    } catch (e) {
      debugPrint('Chat: loadOlderMessages error: $e');
    }
    _loadingMore = false;
    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
    setState(() => _showNewMessageButton = false);
  }

  void _watchPartner() {
    final auth = context.read<AuthProvider>();
    if (auth.partnerUid != null) {
      _partnerSub = _profileRepo.watchUser(auth.partnerUid!).listen((user) {
        if (mounted) {
          if (user != null) {
            final expectedName = auth.repository.partnerName;
            if (expectedName != null && user.name != expectedName) {
              _profileRepo.updateName(uid: user.uid, name: expectedName);
            }
          }
          setState(() {
            _partnerImageUrl = user?.profileImageUrl;
            _partnerName = user?.name;
          });
        }
      });
    }
  }

  void _showEmojiPicker() {
    final emojis = [
      '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂',
      '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋', '😛',
      '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🥸', '🤩', '🥳',
      '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '😣', '😖', '😫',
      '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬', '🤯', '😳',
      '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗', '🤔', '🤭',
      '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄', '😯', '😦', '😧',
      '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐', '🥴', '🤢',
      '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '😈', '👿', '👹',
      '👺', '💀', '☠️', '💩', '🤡', '👻', '👽', '👾', '🤖', '🎃',
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
      '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '♥️',
      '👍', '👎', '👊', '✊', '🤛', '🤜', '👏', '🙌', '👐', '🤲',
      '🤝', '🙏', '✌️', '🤞', '🫰', '🤟', '🤘', '🤙', '👈', '👉',
      '👆', '🖕', '👇', '☝️', '🫵', '✋', '🤚', '🖐', '🖖', '👋',
      '🤗', '💪', '🦵', '🦶', '👂', '🦻', '👃', '🧠', '🫀', '🫁',
      '👀', '👁', '👅', '👄', '🦷', '💋', '🍕', '🍔', '🍟', '🌭',
      '🍿', '🧁', '🍩', '🍪', '🍫', '🍬', '🍭', '🍮', '🍰', '🎂',
      '☕', '🍵', '🥤', '🧃', '🍺', '🍻', '🥂', '🍷', '🥃', '🍸',
      '🌹', '🌸', '🌺', '🌻', '🌷', '💐', '🥀', '🌿', '🍀', '🌼',
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
      '🦁', '🐮', '🐷', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', '🐔',
      '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇', '🐺',
      '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜', '🪰',
      '🌟', '⭐', '🌙', '☀️', '🌈', '☁️', '⚡', '🔥', '💧', '🌊',
      '🎉', '🎊', '🎈', '🎁', '🎀', '🎄', '🎃', '🎆', '🎇', '✨',
      '💎', '👑', '💍', '🔑', '🔒', '🔓', '🔐', '🛡️', '🎯', '🏆',
      '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🎳', '🏓',
      '🎮', '🎲', '🃏', '🀄', '🎯', '🎰', '🚗', '🚕', '🚙', '🚌',
      '🚓', '🚑', '🚒', '🚐', '🛴', '🚲', '🏍️', '✈️', '🚀', '🛸',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: AppColors.textLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Icon(Icons.close, color: AppColors.textLight, size: 20),
                  ),
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: emojis.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    final pos = _controller.selection.baseOffset;
                    final text = _controller.text;
                    if (pos < 0 || pos > text.length) {
                      _controller.text = text + emojis[i];
                    } else {
                      _controller.text = text.substring(0, pos) + emojis[i] + text.substring(pos);
                      _controller.selection = TextSelection.collapsed(offset: pos + emojis[i].length);
                    }
                  },
                  child: Center(child: Text(emojis[i], style: const TextStyle(fontSize: 18))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().currentUser;
    final myUid = authUser?.uid;
    final myImageUrl = authUser?.profileImageUrl;
    final myName = authUser?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showCoupleInfo(context, myName, myImageUrl, _partnerName ?? '', _partnerImageUrl),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: _partnerImageUrl != null && _partnerImageUrl!.isNotEmpty
                    ? cachedMemoryImage(_partnerImageUrl!)
                    : null,
                child: _partnerImageUrl == null || _partnerImageUrl!.isEmpty
                    ? const Icon(Icons.person, size: 14, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(_partnerName ?? KhmerText.messagesTitle, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _newestMessages.isEmpty && _olderMessages.isEmpty
                ? const EmptyStateWidget(message: KhmerText.messageEmpty, icon: Icons.chat_bubble_outline)
                : ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    itemCount: _allMessages.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _allMessages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final message = _allMessages[index];
                      final isMe = message.senderId == myUid;
                      return _ChatBubble(
                        key: ValueKey(message.id),
                        message: message,
                        isMe: isMe,
                        myImageUrl: myImageUrl,
                        partnerImageUrl: _partnerImageUrl,
                        onDoubleTap: () => _ChatBubble._showReactionPicker(context, message.id),
                      );
                    },
                  ),
          ),
          if (_editingMessageId != null)
            Container(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('កំពុងកែសម្រួល...', style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 13, color: AppColors.textLight))),
                  GestureDetector(
                    onTap: _cancelEdit,
                    child: Icon(Icons.close, size: 18, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          if (_replyingTo != null)
            Container(
              color: AppColors.secondary.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.reply_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _replyingTo!.senderName,
                          style: const TextStyle(fontFamily: 'KantumruyPro', fontSize: 12, color: AppColors.primary),
                        ),
                        Text(
                          _replyingTo!.text ?? 'រូបភាព',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 13, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 18, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          if (_sendingImage)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  const SizedBox(width: 10),
                  Text(
                    'កំពុងផ្ញើ $_sentCount/$_totalSending',
                    style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 13, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          if (_showNewMessageButton)
            GestureDetector(
              onTap: _scrollToBottom,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        KhmerText.newMessages,
                        style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'KantumruyPro'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.background, width: 2)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sendingImage ? null : _pickImages,
                    icon: const Icon(Icons.image_outlined, color: AppColors.primary),
                  ),
                  IconButton(
                    onPressed: _showEmojiPicker,
                    icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.primary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _inputFocus,
                      style: const TextStyle(fontFamily: 'KantumruyPro'),
                      decoration: InputDecoration(
                        hintText: KhmerText.messageHint,
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendCurrentMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendCurrentMessage,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCoupleInfo(BuildContext context, String myName, String? myImage, String partnerName, String? partnerImage) {
    final auth = context.read<AuthProvider>();
    final myUid = auth.currentUser?.uid;
    final partnerUid = auth.partnerUid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    if (myUid != null) _showUserProfile(context, myUid);
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: myImage != null && myImage.isNotEmpty
                            ? cachedMemoryImage(myImage)
                            : null,
                        child: myImage == null || myImage.isEmpty
                            ? const Icon(Icons.person, size: 32, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(myName, style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textDark, fontSize: 14)),
                    ],
                  ),
                ),
                const Icon(Icons.favorite, color: AppColors.primary, size: 28),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    if (partnerUid != null) _showUserProfile(context, partnerUid);
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: partnerImage != null && partnerImage.isNotEmpty
                            ? cachedMemoryImage(partnerImage)
                            : null,
                        child: partnerImage == null || partnerImage.isEmpty
                            ? const Icon(Icons.person, size: 32, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(partnerName, style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textDark, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              DateFormat('dd/MM/yyyy').format(AppConstants.relationshipStartDate),
              style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textLight, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(BuildContext context, String uid) async {
    final user = await _profileRepo.getUser(uid);
    if (!context.mounted || user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: user.profileImageUrl.isNotEmpty
                  ? cachedMemoryImage(user.profileImageUrl)
                  : null,
              child: user.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: 44, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 14),
            Text(user.name, style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 20, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(user.email, style: TextStyle(fontFamily: 'KantumruyPro', fontSize: 13, color: AppColors.textLight)),
            const SizedBox(height: 12),
            if (user.phone.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(user.phone, style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textLight, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (user.bio.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  user.bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.textDark, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _cancelEdit() {
    _editingMessageId = null;
    _controller.clear();
  }

  void _cancelReply() {
    _replyingTo = null;
  }

  int _totalSending = 0;
  int _sentCount = 0;

  Future<void> _pickImages() async {
    final List<XFile> picked;
    try {
      if (kIsWeb) {
        final single = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 45, maxWidth: 600, maxHeight: 600);
        picked = single != null ? [single] : [];
      } else {
        picked = await _picker.pickMultiImage(imageQuality: 45, maxWidth: 600, maxHeight: 600);
      }
    } catch (e) {
      debugPrint('_pickImages: pick error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${KhmerText.messageSendImageFail}: $e')),
      );
      return;
    }
    if (!mounted || picked.isEmpty) return;
    final auth = context.read<AuthProvider>().currentUser;
    if (auth == null) return;
    _totalSending = picked.length;
    _sentCount = 0;
    if (mounted) setState(() => _sendingImage = true);

    for (final xFile in picked) {
      try {
        final bytes = await xFile.readAsBytes();
        if (!mounted) return;
        await _chatRepo.sendImageMessage(
          senderId: auth.uid,
          senderName: auth.name,
          imageBytes: bytes,
          imageExtension: xFile.path.split('.').last,
          replyTo: _replyingTo != null
              ? ReplyInfo(
                  messageId: _replyingTo!.id,
                  text: _replyingTo!.text,
                  imageUrl: _replyingTo!.imageUrl,
                  senderName: _replyingTo!.senderName,
                  senderId: _replyingTo!.senderId,
                )
              : null,
        );
      } catch (e) {
        debugPrint('_pickImages: send error for ${xFile.path}: $e');
        if (!mounted) return;
        setState(() => _sendingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${KhmerText.messageSendImageFail}: $e')),
        );
        return;
      }
      if (!mounted) return;
      _sentCount++;
      if (mounted) setState(() {});
    }

    if (!mounted) return;
    setState(() {
      _sendingImage = false;
      _replyingTo = null;
    });
  }

  Future<void> _sendCurrentMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthProvider>().currentUser;
    if (auth == null) return;

    try {
      if (_editingMessageId != null) {
        await _chatRepo.updateMessage(_editingMessageId!, text);
        _editingMessageId = null;
      } else {
        await _chatRepo.sendTextMessage(
          senderId: auth.uid,
          senderName: auth.name,
          text: text,
          replyTo: _replyingTo != null
              ? ReplyInfo(
                  messageId: _replyingTo!.id,
                  text: _replyingTo!.text,
                  imageUrl: _replyingTo!.imageUrl,
                  senderName: _replyingTo!.senderName,
                  senderId: _replyingTo!.senderId,
                )
              : null,
        );
        _replyingTo = null;
      }
      _controller.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('មិនអាចផ្ញើសារបានទេ: $e')),
        );
      }
    }
  }

  void _startReply(MessageModel msg) {
    _replyingTo = msg;
    _inputFocus.requestFocus();
  }

  void _startEdit(MessageModel msg) {
    _editingMessageId = msg.id;
    _controller.text = msg.text ?? '';
    _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    _inputFocus.requestFocus();
  }
}

class _ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? myImageUrl;
  final String? partnerImageUrl;
  final VoidCallback? onDoubleTap;

  const _ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.myImageUrl,
    this.partnerImageUrl,
    this.onDoubleTap,
  });

  void _showActions(BuildContext context, MessageModel msg) {
    final auth = context.read<AuthProvider>();
    final myUid = auth.currentUser?.uid;
    final isMine = msg.senderId == myUid;
    final isMineText = isMine && msg.type == MessageType.text;
    final hasText = msg.text != null && msg.text!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined, color: AppColors.primary),
              title: const Text('ប្រតិកម្ម', style: TextStyle(fontFamily: 'KantumruyPro')),
              onTap: () {
                Navigator.pop(ctx);
                _showReactionPicker(context, msg.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply_outlined, color: AppColors.primary),
              title: const Text('ឆ្លើយតប', style: TextStyle(fontFamily: 'KantumruyPro')),
              onTap: () {
                Navigator.pop(ctx);
                _startReply(context, msg);
              },
            ),
            if (isMineText) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                title: const Text('កែសម្រួល', style: TextStyle(fontFamily: 'KantumruyPro')),
                onTap: () {
                  Navigator.pop(ctx);
                  _startEdit(context, msg);
                },
              ),
            ],
            if (isMine) ...[
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('លុប', style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, msg.id);
                },
              ),
            ],
            if (hasText) ...[
              ListTile(
                leading: const Icon(Icons.copy_outlined, color: AppColors.primary),
                title: const Text('ចម្លង', style: TextStyle(fontFamily: 'KantumruyPro')),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: msg.text!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('បានចម្លងរួចរាល់')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void _showReactionPicker(BuildContext context, String messageId) {
    final state = context.findAncestorStateOfType<_MessagesScreenState>();
    if (state == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['👍', '❤️', '😂', '😮', '😢', '😡'].map((emoji) {
            return GestureDetector(
              onTap: () {
                final userId = context.read<AuthProvider>().currentUser?.uid;
                if (userId != null) {
                  state._chatRepo.toggleReaction(messageId, userId, emoji);
                }
                Navigator.pop(ctx);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  static void _startReply(BuildContext context, MessageModel msg) {
    final state = context.findAncestorStateOfType<_MessagesScreenState>();
    state?._startReply(msg);
  }

  static void _startEdit(BuildContext context, MessageModel msg) {
    final state = context.findAncestorStateOfType<_MessagesScreenState>();
    state?._startEdit(msg);
  }

  static Future<void> _confirmDelete(BuildContext context, String messageId) async {
    final state = context.findAncestorStateOfType<_MessagesScreenState>();
    if (state == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('លុបសារ', style: TextStyle(fontFamily: 'KantumruyPro')),
        content: const Text('តើអ្នកប្រាកដទេ?', style: TextStyle(fontFamily: 'KantumruyPro')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(KhmerText.cancel, style: TextStyle(fontFamily: 'KantumruyPro')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(KhmerText.delete, style: TextStyle(fontFamily: 'KantumruyPro', color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await state._chatRepo.deleteMessage(messageId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), duration: const Duration(seconds: 5)),
          );
        }
      }
    }
  }

  Widget _buildImageContent(BuildContext context) {
    final hasBase64 = message.imageBase64 != null && message.imageBase64!.isNotEmpty;
    final hasImageUrl = message.imageUrl != null && message.imageUrl!.isNotEmpty;

    Widget imageWidget;
    if (hasBase64) {
      imageWidget = Image.memory(
        cachedBase64Decode(message.imageBase64!),
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 200,
          height: 200,
          child: Center(child: Icon(Icons.broken_image, size: 48)),
        ),
      );
    } else if (hasImageUrl) {
      imageWidget = Image.network(
        message.imageUrl!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 200,
          height: 200,
          child: Center(child: Icon(Icons.broken_image, size: 48)),
        ),
      );
    } else {
      imageWidget = const SizedBox(
        width: 200,
        height: 200,
        child: Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
      );
    }

    final viewerUrl = message.imageUrl ?? message.imageBase64;
    return GestureDetector(
      onTap: viewerUrl != null
          ? () => _openImageViewer(context, viewerUrl, message.id)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrl = isMe ? myImageUrl : partnerImageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: hasImage ? cachedMemoryImage(imageUrl) : null,
                child: hasImage ? null : const Icon(Icons.person, size: 18, color: AppColors.primary),
              ),
            ),
          GestureDetector(
            onLongPress: onDoubleTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                  padding: message.type == MessageType.image
                      ? const EdgeInsets.all(4)
                      : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (message.replyTo != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isMe ? Colors.white : AppColors.primary).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: isMe ? Colors.white54 : AppColors.primary,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                message.replyTo!.senderName,
                                  style: TextStyle(
                                    fontFamily: 'KantumruyPro',
                                    fontSize: 11,
                                    color: isMe ? Colors.white70 : colorScheme.onSurfaceVariant,
                                  ),
                              ),
                              const SizedBox(height: 2),
                              if (message.replyTo!.text != null)
                                Text(
                                  message.replyTo!.text!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'KantumruyPro',
                                      fontSize: 12,
                                      color: isMe ? Colors.white60 : colorScheme.onSurfaceVariant,
                                    ),
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.image, size: 14, color: isMe ? Colors.white60 : AppColors.textLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      'រូបភាព',
                                      style: TextStyle(
                                        fontFamily: 'KantumruyPro',
                                        fontSize: 12,
                                        color: isMe ? Colors.white60 : AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      if (message.type == MessageType.text)
                        Text(
                          message.text ?? '',
                          style: TextStyle(
                            fontFamily: 'KantumruyPro',
                            color: isMe ? Colors.white : colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        )
                      else
                        _buildImageContent(context),
                      if (message.reactions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: message.reactions.values.toSet().map((e) {
                              final count = message.reactions.values.where((v) => v == e).length;
                              return Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isMe ? Colors.white : AppColors.background).withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primaryLight, width: 0.5),
                                  ),
                                  child: Text(
                                    count > 1 ? '$e $count' : e,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
            padding: EdgeInsets.only(left: isMe ? 2 : 0, right: isMe ? 0 : 2),
            child: GestureDetector(
              onTap: () => _showActions(context, message),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.more_horiz, size: 18, color: AppColors.textLight),
              ),
            ),
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: hasImage ? cachedMemoryImage(imageUrl) : null,
                child: hasImage ? null : const Icon(Icons.person, size: 18, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
      ],
      ),
    );
  }
}
