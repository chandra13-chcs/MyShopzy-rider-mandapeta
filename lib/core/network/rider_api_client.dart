import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/demo_delivery.dart';

class RiderApiException implements Exception {
  const RiderApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => message;
}

class RiderApiClient {
  RiderApiClient._({http.Client? httpClient, Uri? baseUri})
    : _httpClient = httpClient ?? http.Client(),
      _baseUri = baseUri ?? _defaultBaseUri;

  @visibleForTesting
  RiderApiClient.forTesting({
    required http.Client httpClient,
    required Uri baseUri,
  }) : this._(httpClient: httpClient, baseUri: baseUri);

  static final RiderApiClient instance = RiderApiClient._();

  static const riderId = '00000000-0000-4000-8000-000000000001';
  static const _configuredBaseUrl = String.fromEnvironment(
    'RIDER_API_BASE_URL',
  );
  static const _requestTimeout = Duration(seconds: 15);

  static Uri get _defaultBaseUri {
    if (_configuredBaseUrl.isNotEmpty) {
      return Uri.parse(_configuredBaseUrl);
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return Uri.parse('http://localhost:3000');
    }
    return Uri.parse('http://10.0.2.2:3000');
  }

  final http.Client _httpClient;
  final Uri _baseUri;

  Map<String, String> get _headers => const {
    'Content-Type': 'application/json',
    'X-Rider-Id': riderId,
  };

  Uri _uri(String path) {
    final base = _baseUri.toString().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base/api/v1$path');
  }

  Future<List<DemoDelivery>> getAvailableOrders() async {
    final payload = await _send('GET', '/rider/orders/available');
    final orders = (payload['data'] as Map<String, dynamic>?)?['orders'];
    if (orders is! List) {
      throw const FormatException(
        'The server returned an invalid orders list.',
      );
    }
    return orders
        .map((order) {
          if (order is! Map<String, dynamic>) {
            throw const FormatException(
              'The server returned an invalid order.',
            );
          }
          return DemoDelivery.fromRiderApiJson(order);
        })
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) =>
      _send('POST', '/rider/orders/${Uri.encodeComponent(orderId)}/accept');

  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status,
  ) => _send(
    'PATCH',
    '/rider/orders/${Uri.encodeComponent(orderId)}/status',
    body: {'status': status},
  );

  Future<Map<String, dynamic>> updateLocation(double lat, double lng) => _send(
    'POST',
    '/rider/location',
    body: {'latitude': lat, 'longitude': lng},
  );

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    late final http.Response response;
    try {
      final request = http.Request(method, _uri(path))
        ..headers.addAll(_headers);
      if (body != null) request.body = jsonEncode(body);
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(_requestTimeout);
      response = await http.Response.fromStream(streamedResponse)
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const RiderApiException(
        statusCode: 0,
        code: 'REQUEST_TIMEOUT',
        message: 'The rider service took too long to respond.',
      );
    } on http.ClientException {
      throw const RiderApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: 'Could not connect to the rider service.',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const RiderApiException(
        statusCode: 502,
        code: 'INVALID_SERVER_RESPONSE',
        message: 'The rider service returned an invalid response.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const RiderApiException(
        statusCode: 502,
        code: 'INVALID_SERVER_RESPONSE',
        message: 'The rider service returned an invalid response.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      final errorMap = error is Map<String, dynamic> ? error : const {};
      throw RiderApiException(
        statusCode: response.statusCode,
        code:
            errorMap['code'] as String? ??
            (decoded['success'] == false ? 'RIDER_OFFLINE' : 'REQUEST_FAILED'),
        message:
            errorMap['message'] as String? ??
            decoded['message'] as String? ??
            'The rider request could not be completed.',
      );
    }
    return decoded;
  }
}
