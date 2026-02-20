import 'package:eyesos/features/map/bloc/location_state.dart';
import 'package:eyesos/features/map/bloc/map_bloc.dart';
import 'package:eyesos/features/map/bloc/map_event.dart';
import 'package:eyesos/features/map/bloc/map_state.dart';
import 'package:eyesos/features/map/presentation/widgets/control_button.dart';
import 'package:eyesos/features/map/presentation/widgets/location_time_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

class MapControlButtons extends StatelessWidget {
  final MapController mapController;
  final LocationState locationState;
  final bool isMapReady;
  final VoidCallback onCenterOnLocation;

  const MapControlButtons({
    super.key,
    required this.mapController,
    required this.locationState,
    required this.isMapReady,
    required this.onCenterOnLocation,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, mapState) {
        return Positioned(
          bottom: 20,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (locationState is LocationLoaded) ...[
                LocationTimeBadge(
                  locationState: locationState as LocationLoaded,
                ),
                const SizedBox(height: 10),
              ],
              ControlButton(
                icon: mapState.showRoadRisk
                    ? Icons.visibility
                    : Icons.visibility_off,
                tooltip: mapState.showRoadRisk
                    ? 'Hide Risk Roads'
                    : 'Show Risk Roads',
                onPressed: () => context.read<MapBloc>().add(ToggleRoads()),
                iconColor: Colors.red[700],
              ),
              const SizedBox(height: 10),
              if (!mapState.showLegend)
                ControlButton(
                  icon: Icons.legend_toggle,
                  tooltip: 'Show Legend',
                  onPressed: () => context.read<MapBloc>().add(ToggleLegend()),
                  iconColor: Colors.red[700],
                ),
              const SizedBox(height: 10),
              ControlButton(
                icon: Icons.add,
                tooltip: 'Zoom In',
                iconColor: Colors.red[700],
                onPressed: () {
                  mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom + 1,
                  );
                },
              ),
              const SizedBox(height: 10),
              ControlButton(
                icon: Icons.remove,
                tooltip: 'Zoom Out',
                iconColor: Colors.red[700],
                onPressed: () {
                  mapController.move(
                    mapController.camera.center,
                    mapController.camera.zoom - 1,
                  );
                },
              ),
              const SizedBox(height: 10),
              ControlButton(
                icon: Icons.my_location,
                tooltip: 'Center on Current Location',
                iconColor: Colors.white,
                color: Colors.red[700],
                onPressed: onCenterOnLocation,
                isLoading: locationState is LocationLoading && isMapReady,
              ),
            ],
          ),
        );
      },
    );
  }
}
