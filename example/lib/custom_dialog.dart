import 'package:flutter/material.dart';

void showDefaultLoading({
  @required BuildContext context,
  String title,
  bool barrierDismissible = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    child: Align(
      alignment: Alignment.center,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text(
              title ?? '正在加载...',
              style: Theme.of(context).textTheme.bodyText2.copyWith(
                    color: Colors.black87,
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}
