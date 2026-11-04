import 'package:supabase_flutter/supabase_flutter.dart';

import '/features/library/domain/library_models.dart';

/// Acesso à biblioteca de peças e tópicos, separado da tela para poder ser
/// testado sem banco.
abstract class LibraryRepository {
  Future<AreaLibrary> loadArea({required String userId, required String area});

  Future<void> createPeca({required String userId, required String area, required String name});

  Future<void> updatePeca({
    required String userId,
    required String area,
    required String oldName,
    required String newName,
    required String? headerTemplate,
  });

  Future<void> deletePeca({required String userId, required String area, required String name});

  Future<void> updateTopic({
    required int id,
    required String title,
    required String content,
    required String preview,
    required List<String> variables,
  });

  Future<void> deleteTopic(int id);

  Future<TopicKit> createKit({
    required String userId,
    required String area,
    required String pecaName,
    required String name,
    required List<int> topicIds,
  });

  Future<void> deleteKit(int id);
}

class SupabaseLibraryRepository implements LibraryRepository {
  SupabaseLibraryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AreaLibrary> loadArea({required String userId, required String area}) async {
    final pecas = await _client
        .from('pecas')
        .select('peca_name, header_template')
        .eq('user_id', userId)
        .eq('area_name', area)
        .order('id', ascending: true);

    final topics = await _client
        .from('topics')
        .select()
        .eq('user_id', userId)
        .eq('area_name', area)
        .order('id', ascending: true);

    final kits = await _client
        .from('topic_kits')
        .select('id, peca_name, name, topic_ids')
        .eq('user_id', userId)
        .eq('area_name', area)
        .order('name', ascending: true);

    return AreaLibrary(
      kits: (kits as List).map(_kitFromRow).toList(),
      pecas: (pecas as List)
          .map((row) => PecaItem(
                name: row['peca_name'].toString(),
                headerTemplate: row['header_template'] as String?,
              ))
          .toList(),
      topics: (topics as List)
          .map((row) => TopicItem(
                id: row['id'] as int,
                pecaName: row['peca_name'].toString(),
                title: row['title'].toString(),
                content: row['content'].toString(),
                preview: row['preview'].toString(),
                variables: (row['variables'] as List).cast<String>(),
              ))
          .toList(),
    );
  }

  @override
  Future<void> createPeca({required String userId, required String area, required String name}) async {
    await _client.from('pecas').insert({
      'user_id': userId,
      'area_name': area,
      'peca_name': name,
    });
  }

  @override
  Future<void> updatePeca({
    required String userId,
    required String area,
    required String oldName,
    required String newName,
    required String? headerTemplate,
  }) async {
    await _client
        .from('pecas')
        .update({'peca_name': newName, 'header_template': headerTemplate})
        .eq('user_id', userId)
        .eq('area_name', area)
        .eq('peca_name', oldName);

    if (newName != oldName) {
      await _client
          .from('topics')
          .update({'peca_name': newName})
          .eq('user_id', userId)
          .eq('area_name', area)
          .eq('peca_name', oldName);
      await _client
          .from('topic_kits')
          .update({'peca_name': newName})
          .eq('user_id', userId)
          .eq('area_name', area)
          .eq('peca_name', oldName);
    }
  }

  @override
  Future<void> deletePeca({required String userId, required String area, required String name}) async {
    await _client
        .from('topic_kits')
        .delete()
        .eq('user_id', userId)
        .eq('area_name', area)
        .eq('peca_name', name);
    await _client
        .from('topics')
        .delete()
        .eq('user_id', userId)
        .eq('area_name', area)
        .eq('peca_name', name);
    await _client
        .from('pecas')
        .delete()
        .eq('user_id', userId)
        .eq('area_name', area)
        .eq('peca_name', name);
  }

  @override
  Future<void> updateTopic({
    required int id,
    required String title,
    required String content,
    required String preview,
    required List<String> variables,
  }) async {
    await _client.from('topics').update({
      'title': title,
      'content': content,
      'preview': preview,
      'variables': variables,
    }).eq('id', id);
  }

  @override
  Future<void> deleteTopic(int id) async {
    await _client.from('topics').delete().eq('id', id);
  }

  @override
  Future<TopicKit> createKit({
    required String userId,
    required String area,
    required String pecaName,
    required String name,
    required List<int> topicIds,
  }) async {
    final row = await _client
        .from('topic_kits')
        .insert({
          'user_id': userId,
          'area_name': area,
          'peca_name': pecaName,
          'name': name,
          'topic_ids': topicIds,
        })
        .select('id, peca_name, name, topic_ids')
        .single();
    return _kitFromRow(row);
  }

  @override
  Future<void> deleteKit(int id) async {
    await _client.from('topic_kits').delete().eq('id', id);
  }

  TopicKit _kitFromRow(dynamic row) => TopicKit(
        id: row['id'] as int,
        pecaName: row['peca_name'].toString(),
        name: row['name'].toString(),
        topicIds: (row['topic_ids'] as List).cast<int>(),
      );
}
