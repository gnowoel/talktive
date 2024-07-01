import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../models/room.dart';
import '../services/firedata.dart';
import '../services/history.dart';
import '../widgets/health.dart';
import '../widgets/input.dart';
import '../widgets/message_list.dart';

class ChatPage extends StatefulWidget {
  final Room room;
  final int recordMessageCount;
  final double recordScrollOffset;

  const ChatPage({
    super.key,
    required this.room,
    this.recordMessageCount = 1,
    this.recordScrollOffset = 0.0,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late ThemeData theme;
  late FocusNode focusNode;
  late ScrollController scrollController;
  late Firedata firedata;
  late History history;
  late StreamSubscription roomSubscription;
  late StreamSubscription messagesSubscription;

  late Room _room;
  late List<Message> _messages;

  double scrollOffset = 0.0;
  // bool oneShot = true;

  @override
  void initState() {
    super.initState();

    focusNode = FocusNode();
    scrollOffset = widget.recordScrollOffset;
    scrollController = ScrollController(
      initialScrollOffset: scrollOffset,
    );

    firedata = Provider.of<Firedata>(context, listen: false);
    history = Provider.of<History>(context, listen: false);

    // History records shouldn't trigger the action
    if (!widget.room.isNew && !widget.room.isFromRecord) {
      firedata.createAccess(widget.room.id);
    }

    _room = widget.room;
    _messages = [];

    _addHistoryRecord(_room);

    roomSubscription = firedata.subscribeToRoom(widget.room.id).listen((room) {
      // if (oneShot) {
      //   firedata.createAccess(widget.room.id);
      //   oneShot = false;
      // }
      setState(() => _room = room);
    });

    messagesSubscription =
        firedata.subscribeToMessages(widget.room.id).listen((messages) {
      setState(() => _messages = messages);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  void _updateScrollOffset(double position) {
    scrollOffset = position;
  }

  Future<void> _addHistoryRecord(Room room) async {
    await history.saveRecord(
      room: room,
      messageCount: _messages.length,
      scrollOffset: scrollOffset,
    );
  }

  @override
  void dispose() {
    messagesSubscription.cancel();
    roomSubscription.cancel();

    _addHistoryRecord(_room);

    scrollController.dispose();
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: Text(_room.userName),
        actions: [
          Health(room: _room),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: _buildLayoutBuilder(),
      ),
    );
  }

  Widget _buildLayoutBuilder() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 600) {
        return Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(24),
              ),
              border: Border.all(color: theme.colorScheme.secondaryContainer),
            ),
            constraints: const BoxConstraints(minWidth: 324, maxWidth: 576),
            child: _buildColumn(),
          ),
        );
      } else {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
          ),
          child: _buildColumn(),
        );
      }
    });
  }

  Widget _buildColumn() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: MessageList(
            focusNode: focusNode,
            scrollController: scrollController,
            recordMessageCount: widget.recordMessageCount,
            updateScrollOffset: _updateScrollOffset,
            room: _room,
            messages: _messages,
          ),
        ),
        Input(
          focusNode: focusNode,
          room: _room,
        ),
      ],
    );
  }
}
