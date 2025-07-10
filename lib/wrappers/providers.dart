import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/avatar.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../services/firestore.dart';
import '../services/messaging.dart';
import '../services/service_locator.dart';
import '../services/storage.dart';
import '../services/ad_service/room_transition_ads.dart';

class Providers extends StatelessWidget {
  final Widget child;

  const Providers({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Create Firebase service instances
    final fireauth = Fireauth(Fireauth.firebaseAuth);
    final firedata = Firedata(Firedata.firebaseDatabase);
    final firestore = Firestore(Firestore.firebaseFirestore);

    return MultiProvider(
      providers: [
        // Use ServiceLocator to create optimized providers
        ...ServiceLocator.createProviders(
          fireauth: fireauth,
          firedata: firedata,
          firestore: firestore,
        ),

        // Additional services not managed by ServiceLocator
        Provider(create: (context) => Storage()),
        Provider(create: (context) => Messaging()),
        ChangeNotifierProvider(create: (context) => Avatar()),

        // Room transition ads - simplified approach
        ChangeNotifierProvider.value(value: RoomTransitionAds.instance),
      ],
      child: child,
    );
  }
}
