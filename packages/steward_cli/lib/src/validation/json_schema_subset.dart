class SchemaValidationResult {
  const SchemaValidationResult({
    required this.valid,
    required this.diagnostics,
  });

  final bool valid;
  final List<String> diagnostics;
}

SchemaValidationResult validateJsonSchemaSubset(
  final Object? value,
  final Map<String, dynamic> schema,
) {
  final diagnostics = <String>[];
  _validateValue(value, schema, r'$', schema, diagnostics);
  return SchemaValidationResult(
    valid: diagnostics.isEmpty,
    diagnostics: diagnostics,
  );
}

void _validateObject(
  final Map<String, dynamic> value,
  final Map<String, dynamic> schema,
  final String path,
  final Map<String, dynamic> rootSchema,
  final List<String> diagnostics,
) {
  final required = ((schema['required'] as List?) ?? const <Object?>[])
      .cast<String>();
  final properties = Map<String, dynamic>.from(
    (schema['properties'] as Map?) ?? const {},
  );

  for (final field in required) {
    if (!value.containsKey(field)) {
      diagnostics.add('$path.$field is required.');
    }
  }

  if (schema['additionalProperties'] == false) {
    for (final key in value.keys) {
      if (!properties.containsKey(key)) {
        diagnostics.add('$path.$key is not declared by schema.');
      }
    }
  }

  for (final entry in properties.entries) {
    if (!value.containsKey(entry.key)) continue;
    _validateValue(
      value[entry.key],
      Map<String, dynamic>.from(entry.value as Map),
      '$path.${entry.key}',
      rootSchema,
      diagnostics,
    );
  }
}

void _validateValue(
  final Object? value,
  final Map<String, dynamic> schema,
  final String path,
  final Map<String, dynamic> rootSchema,
  final List<String> diagnostics,
) {
  final ref = schema[r'$ref'];
  if (ref is String) {
    _validateValue(
      value,
      _resolveRef(ref, rootSchema),
      path,
      rootSchema,
      diagnostics,
    );
    return;
  }

  if (schema.containsKey('const') && value != schema['const']) {
    diagnostics.add('$path must be ${schema['const']}.');
  }

  final enumValues = schema['enum'];
  if (enumValues is List && !enumValues.contains(value)) {
    diagnostics.add('$path must be one of: ${enumValues.join(', ')}.');
  }

  final type = schema['type'] as String?;
  if (type != null && !_matchesSimpleType(value, type)) {
    diagnostics.add('$path must be $type.');
    return;
  }

  if (type == 'string' && value is String) {
    final minLength = schema['minLength'];
    if (minLength is int && value.length < minLength) {
      diagnostics.add('$path must have length at least $minLength.');
    }
  }

  if (type == 'array' && value is List) {
    final minItems = schema['minItems'];
    if (minItems is int && value.length < minItems) {
      diagnostics.add('$path must contain at least $minItems item(s).');
    }
    final itemSchema = schema['items'];
    if (itemSchema is Map) {
      for (var index = 0; index < value.length; index++) {
        _validateValue(
          value[index],
          Map<String, dynamic>.from(itemSchema),
          '$path[$index]',
          rootSchema,
          diagnostics,
        );
      }
    }
  }

  if (type == 'object' && value is Map) {
    _validateObject(
      Map<String, dynamic>.from(value),
      schema,
      path,
      rootSchema,
      diagnostics,
    );
  }

  final allOf = schema['allOf'];
  if (allOf is List) {
    for (final item in allOf) {
      if (item is Map) {
        _validateValue(
          value,
          Map<String, dynamic>.from(item),
          path,
          rootSchema,
          diagnostics,
        );
      }
    }
  }

  final ifSchema = schema['if'];
  final thenSchema = schema['then'];
  if (ifSchema is Map && thenSchema is Map) {
    if (_matchesSchemaPredicate(value, Map<String, dynamic>.from(ifSchema))) {
      _validateValue(
        value,
        Map<String, dynamic>.from(thenSchema),
        path,
        rootSchema,
        diagnostics,
      );
    }
  }
}

bool _matchesSimpleType(final Object? value, final String type) =>
    switch (type) {
      'array' => value is List,
      'object' => value is Map,
      'string' => value is String,
      'boolean' => value is bool,
      'number' => value is num,
      'integer' => value is int,
      _ => true,
    };

bool _matchesSchemaPredicate(
  final Object? value,
  final Map<String, dynamic> schema,
) {
  if (schema['properties'] case final Map properties when value is Map) {
    for (final entry in properties.entries) {
      final property = entry.value;
      if (property is! Map) continue;
      if (property.containsKey('const') &&
          value[entry.key] != property['const']) {
        return false;
      }
    }
  }
  return true;
}

Map<String, dynamic> _resolveRef(
  final String ref,
  final Map<String, dynamic> rootSchema,
) {
  if (!ref.startsWith('#/')) {
    throw UnsupportedError('Only local schema refs are supported: $ref');
  }
  Object? cursor = rootSchema;
  for (final segment in ref.substring(2).split('/')) {
    if (cursor is! Map) {
      throw StateError('Invalid schema ref: $ref');
    }
    cursor = cursor[segment];
  }
  if (cursor is! Map) {
    throw StateError('Schema ref does not point to an object: $ref');
  }
  return Map<String, dynamic>.from(cursor);
}
