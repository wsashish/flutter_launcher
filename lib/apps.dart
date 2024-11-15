import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';

final modeProvider = StateProvider<DisplayMode>((ref) => DisplayMode.Grid);

class AppsPage extends StatefulWidget {
  @override
  _AppsPageState createState() => _AppsPageState();
}

enum DisplayMode {
  Grid,
  List,
}

class _AppsPageState extends State<AppsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer(
      builder: (context, ref, _) {
        final appsInfo = ref.watch(appsProvider);
        final mode = ref.watch(modeProvider);
        return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              actionsIconTheme:
                  IconThemeData(color: Theme.of(context).colorScheme.primary),
              iconTheme:
                  IconThemeData(color: Theme.of(context).colorScheme.primary),
              backgroundColor: Colors.transparent,
              actions: [
                IconButton(
                  icon: Icon(
                      mode == DisplayMode.Grid ? Icons.list : Icons.grid_on),
                  onPressed: () {
                    ref.read(modeProvider.notifier).update((state) =>
                        mode == DisplayMode.Grid
                            ? DisplayMode.List
                            : DisplayMode.Grid);
                  },
                )
              ],
            ),
            body: appsInfo.when(
                data: (List<Application> apps) => mode == DisplayMode.List
                    ? ListView.builder(
                        itemCount: apps.length,
                        itemBuilder: (BuildContext context, int index) {
                          ApplicationWithIcon app =
                              apps[index] as ApplicationWithIcon;
                          return ListTile(
                            leading: Image.memory(
                              app.icon,
                              width: 40,
                            ),
                            title: Text(app.appName),
                            onTap: () => DeviceApps.openApp(app.packageName),
                          );
                        },
                      )
                    : GridView(
                        padding: const EdgeInsets.fromLTRB(
                            16.0, kToolbarHeight + 16.0, 16.0, 16.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        children: [
                          ...apps.map((app) => AppGridItem(
                                application: app as ApplicationWithIcon?,
                              ))
                        ],
                      ),
                loading: () => Center(
                      child: CircularProgressIndicator(),
                    ),
                error: (e, s) => Container()));
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class AppGridItem extends StatelessWidget {
  final ApplicationWithIcon? application;
  const AppGridItem({
    this.application,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        DeviceApps.openApp(application!.packageName);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Image.memory(
              application!.icon,
              fit: BoxFit.contain,
              width: 40,
            ),
          ),
          Text(
            application!.appName,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
