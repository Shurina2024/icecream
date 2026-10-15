import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: JuiceApp(),
      ),
    );

class JuiceApp extends StatefulWidget {
  const JuiceApp({super.key});

  @override
  State<JuiceApp> createState() => _JuiceAppState();
}

class _JuiceAppState extends State<JuiceApp> {
  final drinks = {
    '🍊 オレンジジュース': 400,
    '🍎 アップルジュース': 400,
    '🍇 グレープジュース': 450,
  };

  String drink = '🍊 オレンジジュース';

  final fruits = <String>{};

  int order = 0;
  bool straw = false;
  bool napkin = false;
  String receipt = '';

  // 5秒チャレンジ用
  final Stopwatch stopwatch = Stopwatch();
  Timer? timer;

  double seconds = 0.00;
  bool running = false;
  bool challenged = false;
  bool challengeSuccess = false;

  Widget choices(
    Iterable<String> items,
    String value,
    void Function(String) change,
  ) =>
      Wrap(
        spacing: 6,
        children: [
          for (final s in items)
            ChoiceChip(
              label: Text(s),
              selected: value == s,
              onSelected: (_) => setState(() => change(s)),
            ),
        ],
      );

  // 5秒チャレンジをスタート
  void startChallenge() {
    stopwatch.reset();
    stopwatch.start();

    setState(() {
      running = true;
      challenged = false;
      challengeSuccess = false;
      seconds = 0.00;
    });

    timer?.cancel();

    timer = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) {
        setState(() {
          seconds = stopwatch.elapsedMilliseconds / 1000;
        });
      },
    );
  }

  // 5秒チャレンジをストップ
  void stopChallenge() {
    stopwatch.stop();
    timer?.cancel();

    final result = stopwatch.elapsedMilliseconds / 1000;

    setState(() {
      seconds = result;
      running = false;
      challenged = true;

      // 4.95秒〜5.05秒なら成功
      challengeSuccess = result >= 4.95 && result <= 5.05;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // チャレンジ成功ならトッピング代0円
    final toppingPrice =
        challengeSuccess ? 0 : fruits.length * 100;

    final subtotal = drinks[drink]! + toppingPrice;

    final tax = subtotal ~/ 10;
    final total = subtotal + tax;

    // ジュースの表示
    final photo = SizedBox(
      width: 190,
      height: 145,
      child: Stack(
        children: [
          Center(
            child: Text(
              '🥤',
              style: const TextStyle(fontSize: 90),
            ),
          ),
          Positioned(
            top: 35,
            right: 25,
            child: SizedBox(
              width: 80,
              child: Text(
                fruits.join(),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ],
      ),
    );

    // 商品選択
    final products = choices(
      drinks.keys.map(
        (s) => '$s  ${drinks[s]}円',
      ),
      '$drink  ${drinks[drink]}円',
      (s) => drink = s.substring(
        0,
        s.lastIndexOf('  '),
      ),
    );

    // トッピング
    final toppings = Wrap(
      spacing: 6,
      children: [
        for (final s in ['🍓', '🍋', '🫐', '🥝', '🍌'])
          FilterChip(
            label: Text(s),
            selected: fruits.contains(s),
            onSelected: (v) => setState(() {
              if (v) {
                fruits.add(s);
              } else {
                fruits.remove(s);
              }
            }),
          ),
      ],
    );

    // 5秒チャレンジ
    final challenge = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '⏱️ 5秒チャレンジ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '5秒ぴったりを狙おう！\n成功するとフルーツトッピング無料！',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              '${seconds.toStringAsFixed(2)} 秒',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (!running)
              FilledButton(
                onPressed: startChallenge,
                child: const Text('スタート'),
              ),

            if (running)
              FilledButton(
                onPressed: stopChallenge,
                child: const Text('ストップ！'),
              ),

            const SizedBox(height: 12),

            if (challenged && challengeSuccess)
              const Text(
                '🎉 成功！トッピング無料！',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

            if (challenged && !challengeSuccess)
              Text(
                seconds < 4.95
                    ? '😢 ちょっと早い！もう一回挑戦！'
                    : '😢 ちょっと遅い！もう一回挑戦！',
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
          ],
        ),
      ),
    );

    // 無料サービス
    Widget supply(
      String label,
      bool value,
      void Function(bool) change,
    ) =>
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) =>
                  setState(() => change(v ?? false)),
            ),
            Text(label),
          ],
        );

    final supplies = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        supply(
          '🥤 ストロー（無料）',
          straw,
          (v) => straw = v,
        ),
        supply(
          '🧻 紙ナプキン（無料）',
          napkin,
          (v) => napkin = v,
        ),
      ],
    );

    // 金額
    final bill = Column(
      children: [
        if (challengeSuccess && fruits.isNotEmpty)
          Text(
            '🎉 トッピング ${fruits.length * 100}円 → 無料！',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

        Text(
          '税抜 $subtotal 円 / 消費税 $tax 円',
        ),

        Text(
          '合計 $total 円',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    // 注文ボタン
    final submit = Center(
      child: FilledButton(
        onPressed: () => setState(() {
          order = Random().nextInt(999) + 1;

          receipt =
              '$drink  ${drinks[drink]}円\n'
              'フルーツ: ${fruits.isEmpty ? 'なし' : fruits.join(' ')}\n'
              '5秒チャレンジ: ${challengeSuccess ? '成功 🎉' : '失敗'}\n'
              'トッピング料金: ${challengeSuccess ? '無料' : '${fruits.length * 100}円'}\n'
              '🥤 ストロー: ${straw ? 'あり' : 'なし'}\n'
              '🧻 紙ナプキン: ${napkin ? 'あり' : 'なし'}\n'
              '税抜: $subtotal 円 / 消費税（10%）: $tax 円\n'
              '合計: $total 円';
        }),
        child: const Text('注文する'),
      ),
    );

    // 注文票
    final ticket = order == 0
        ? const SizedBox.shrink()
        : Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '注文番号 #$order',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(receipt),
                ],
              ),
            ),
          );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          '🍹 Juice 屋台注文アプリ',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(child: photo),

              const Text('ジュースを選ぶ'),
              products,

              const SizedBox(height: 16),

              const Text(
                'フルーツトッピング（1種類100円）',
              ),
              toppings,

              const SizedBox(height: 20),

              challenge,

              const SizedBox(height: 16),

              const Text('無料サービス'),
              supplies,

              const Divider(),

              bill,

              const SizedBox(height: 16),

              submit,

              const SizedBox(height: 16),

              ticket,
            ],
          ),
        ),
      ),
    );
  }
}