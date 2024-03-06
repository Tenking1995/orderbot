import 'dart:async';

import 'package:flutter/material.dart';
import 'package:orderbot/models/bot.dart';
import 'package:orderbot/models/order.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'SE Take Home Assigment'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Order> _orderList = [];
  final List<Bot> _botList = [];

  void _addNewOrder(bool isVIP) {
    setState(() {
      // Assign Uniuqe Id
      var uuid = const Uuid();
      var id = uuid.v1();
      var order = Order(orderId: id, isVIP: isVIP, isPending: true);
      // Add to order list
      _orderList.add(order);
      // Make sure process VIP order first
      var vipOrders = _orderList.where((element) => element.isVIP == true).toList();
      var normalOrders = _orderList.where((element) => element.isVIP == false).toList();
      _orderList = vipOrders + normalOrders;
      // Assign to available bot to process the order
      var bot = _botList.where((element) => element.proceesingOrder == null).firstOrNull;
      if (bot?.botId != null) {
        processOrder(bot!.botId!);
      }
    });
  }

  void _increseBot() {
    setState(() {
      // Assign Uniuqe Id
      var uuid = const Uuid();
      var id = uuid.v1();
      var order = Bot(botId: id);
      // Add to order list
      _botList.add(order);
      // Process the order
      processOrder(id);
    });
  }

  void _decreaseBot() {
    setState(() {
      // Remove the latest bot from list if available
      if (_botList.isNotEmpty) {
        var bot = _botList[0];
        // Release the processing order if available
        if (bot.proceesingOrder != null) {
          bot.proceesingOrder?.isProcessing = false;
        }
        // Remove the bot
        _botList.removeAt(0);
      }
    });
  }

  void processOrder(String botId) async {
    // Get the rest of pending orders
    var currentList = _orderList.where((element) => element.isPending != false && element.isProcessing != true);
    do {
      // Process first order if available
      if (currentList.isNotEmpty) {
        var order = currentList.first;
        // Update the order processing status
        order.isProcessing = true;
        // Assign the order to available bot
        _botList.where((element) => element.botId == botId).firstOrNull?.proceesingOrder = order;
        setState(() {});
        // Assume processing the order now
        await Future.delayed(const Duration(seconds: 10));
        // Not to proceed when bot removed
        if (_botList.where((element) => element.botId == botId).firstOrNull != null) {
          // Update the order status and remove the order from the bot
          order.isPending = false;
          _botList.where((element) => element.botId == botId).firstOrNull?.proceesingOrder = null;
        }
        setState(() {});
      }
    } while (currentList.isNotEmpty && _botList.where((element) => element.botId == botId).firstOrNull != null);
  }

  @override
  Widget build(BuildContext context) {
    var pendingOrders = _orderList.where((element) => element.isPending != false && element.isProcessing != true).toList();
    var completedOrders = _orderList.where((element) => element.isPending == false).toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Divider(),
            const Text('Bot List'),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _botList.length,
                itemBuilder: (_, index) {
                  var item = _botList[index];
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    color: Colors.orange.withOpacity(0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bot Id: ${item.botId}'),
                        Text('Processing Order Id: ${item.proceesingOrder != null ? item.proceesingOrder?.orderId : 'IDLE'}'),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            const Text('Order List'),
            const Divider(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Pending'),
                        Expanded(
                          child: ListView.builder(
                            itemCount: pendingOrders.length,
                            itemBuilder: (_, index) {
                              var item = pendingOrders[index];
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                color: Colors.blue.withOpacity(0.5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Order Id: ${item.orderId.toString()}'),
                                    Text('VIP: ${item.isVIP}'),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Completed'),
                        Expanded(
                          child: ListView.builder(
                            itemCount: completedOrders.length,
                            itemBuilder: (_, index) {
                              var item = completedOrders[index];
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                color: Colors.blue.withOpacity(0.5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Order Id: ${item.orderId.toString()}'),
                                    Text('VIP: ${item.isVIP}'),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _addNewOrder(false);
                },
                child: const Text('New Normal Order'),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _addNewOrder(true);
                },
                child: const Text('New VIP Order'),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _increseBot();
                },
                child: const Text('+ Bot'),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _decreaseBot();
                },
                child: const Text('- Bot'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
