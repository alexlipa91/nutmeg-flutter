import 'package:flutter/material.dart';
import 'package:nutmeg/api/CloudFunctionsUtils.dart';
import 'package:nutmeg/utils/UiUtils.dart';

import 'Avatar.dart';
import 'ModalBottomSheet.dart';
import 'PlayerBottomModal.dart';
import 'Texts.dart';

class FeedbackBottomModal {
  static Future feedbackAction(BuildContext context) async {
    final TextEditingController textEditingController = TextEditingController();

    await ModalBottomSheet.showNutmegModalBottomSheet(
      context,
      Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: BottomModalWithTopImage(
          title: "Give us feedback",
          subtitle: "Help us improve Nutmeg for you",
          content: Column(children: [
            TextField(
                style: TextPalette.getBodyText(Palette.black),
                controller: textEditingController,
                decoration: InputDecoration(
                    fillColor: Palette.greyLighter,
                    filled: true,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(10.0),
                    )),
                maxLines: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TappableLinkText(
                    text: "DONE",
                    onTap: (BuildContext context) async {
                      Navigator.pop(context);
                    })
              ],
            )
          ]),
          topImage: CircleAvatar(
              backgroundColor: Palette.white,
              radius: 38,
              child: NutmegAvatar(34)),
        ),
      ),
    );

    if (textEditingController.text.isNotEmpty) {
      CloudFunctionsClient().post("feedback",
          {"text": textEditingController.text});

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Thanks for your feedback!")));
    }
  }
}
