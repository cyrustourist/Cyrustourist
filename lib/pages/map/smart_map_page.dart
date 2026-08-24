*** Begin Patch
*** Update File: smart_map_page_file12_destination_flow_fixed_v4.dart
@@
   bool originMode = true;
   bool searching = false;
+  bool _selectingResult = false;
+  int _searchGeneration = 0;
   Timer? searchTimer;
@@
   Future<void> searchCurrentField() async {
     searchTimer?.cancel();
+    final generation = ++_searchGeneration;

-    if (searching || _selectingResult) {
+    if (_selectingResult) {
       return;
     }

     final controller = originMode
         ? originController
         : destinationController;

     await performSearch(
       controller.text,
+      autoSelectDestination: !originMode,
+      requestGeneration: generation,
     );
   }
@@
   void autoCompleteSearch(String value) {
     searchTimer?.cancel();
+    final generation = ++_searchGeneration;

     searchTimer = Timer(
       const Duration(milliseconds: 500),
       () {
-        if (value.trim().length >= 2) {
-          performSearch(value);
+        if (value.trim().length >= 2 &&
+            generation == _searchGeneration) {
+          performSearch(
+            value,
+            requestGeneration: generation,
+          );
         }
       },
     );
   }

   Future<void> performSearch(
     String query, {
+    bool autoSelectDestination = false,
+    int? requestGeneration,
   }) async {
@@
       final data =
           await widget.searchPlaces(
         cleanQuery,
       );

-      if (!mounted) return;
+      if (!mounted ||
+          (requestGeneration != null &&
+              requestGeneration != _searchGeneration)) {
+        return;
+      }
+
+      if (autoSelectDestination && !originMode) {
+        Map<String, dynamic>? validResult;
+
+        for (final item in data) {
+          final lat = double.tryParse(
+            item['lat']?.toString() ?? '',
+          );
+          final lon = double.tryParse(
+            item['lon']?.toString() ?? '',
+          );
+
+          if (lat != null &&
+              lon != null &&
+              lat >= -90 &&
+              lat <= 90 &&
+              lon >= -180 &&
+              lon <= 180) {
+            validResult = item;
+            break;
+          }
+        }
+
+        if (validResult != null) {
+          setState(() {
+            searching = false;
+          });
+
+          selectResult(validResult);
+          return;
+        }
+      }

       setState(() {
         results = data;
@@
   void selectResult(
     Map<String, dynamic> result,
   ) {
+    if (_selectingResult) return;
+
     final lat = double.tryParse(
       result['lat']?.toString() ?? '',
     );
@@
     } else {
+      _selectingResult = true;
+      searchTimer?.cancel();
+
       widget.onDestinationSelected(
         point,
         name,
@@
       // Close the search sheet first. The parent page has already
       // switched to destinationConfirmation in _selectDestination.
-      Navigator.of(context).pop();
+      if (mounted) {
+        Navigator.of(context).pop();
+      }
     }
   }
*** End Patch

*** Begin Patch
*** Update File: smart_map_page_file12_destination_flow_fixed_v4.dart
@@
   // After selecting a tourist destination, show a dedicated
   // confirmation page instead of returning to the search panel.
   bool destinationConfirmation = false;
+  bool _searchSheetOpen = false;
@@
   void openSearch({
     bool destination = false,
   }) {
+    if (_searchSheetOpen) return;
+
+    _searchSheetOpen = true;
+
     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
@@
           tr: tr,
         );
       },
-    );
+    ).whenComplete(() {
+      _searchSheetOpen = false;
+    });
   }
*** End Patch

*** Begin Patch
*** Update File: smart_map_page_file12_destination_flow_fixed_v4.dart
@@
-                      onPressed: searching
-                          ? null
-                          : searchCurrentField,
+                      onPressed: searchCurrentField,
*** End Patch
