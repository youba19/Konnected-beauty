import 'dart:convert';

import '../../models/campaign_chat_message.dart';
import 'api_response_helper.dart';
import 'http_interceptor.dart';

class CampaignMessagesService {
  /// GET [ApiBaseUrl.value]/campaign-messages/campaign/:campaignId
  /// Fetches all pages when the API returns [totalPages] > 1.
  static Future<Map<String, dynamic>> getCampaignMessages({
    required String campaignId,
    int limit = 100,
  }) async {
    if (campaignId.isEmpty) {
      return ApiResponseHelper.failureFromException(
        ArgumentError('Campaign ID is required'),
        context: 'getCampaignMessages',
        data: <CampaignChatMessageItem>[],
      );
    }

    try {
      final all = <CampaignChatMessageItem>[];
      var page = 1;
      var totalPages = 1;

      do {
        final response = await HttpInterceptor.authenticatedRequest(
          method: 'GET',
          endpoint: '/campaign-messages/campaign/$campaignId',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          queryParameters: {
            'page': '$page',
            'limit': '$limit',
          },
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          return ApiResponseHelper.fromHttpResponse(
            response,
            context: 'getCampaignMessages',
            defaultData: all,
          );
        }

        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final rawList = responseData['data'];

        final tp = responseData['totalPages'];
        if (tp is int) {
          totalPages = tp;
        } else {
          totalPages = int.tryParse(tp?.toString() ?? '1') ?? 1;
        }

        if (rawList is List) {
          for (final e in rawList) {
            final m = CampaignChatMessageItem.tryParse(e);
            if (m != null) all.add(m);
          }
        }

        page++;
      } while (page <= totalPages && page <= 100);

      return ApiResponseHelper.success(
        data: all,
        statusCode: 200,
        extra: {'total': all.length},
      );
    } catch (e, st) {
      return ApiResponseHelper.failureFromException(
        e,
        stackTrace: st,
        context: 'getCampaignMessages',
        data: <CampaignChatMessageItem>[],
      );
    }
  }
}
