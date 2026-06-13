import '../contracts/claim_contracts.dart';

const _supportedClaims = {
  'stewardship_protocol',
  'steward_presence',
  'proven_repo_steward',
  'sub_steward',
  'harness_ready',
  'fully_adopted',
};

class ClaimCheckResult {
  const ClaimCheckResult({
    required this.claim,
    required this.valid,
    required this.diagnostics,
    required this.nonClaims,
  });

  final String claim;
  final bool valid;
  final List<String> diagnostics;
  final List<String> nonClaims;

  Map<String, dynamic> toJson() => ClaimCheckPayload(
    claim: claim,
    valid: valid,
    diagnostics: diagnostics,
    nonClaims: nonClaims,
  ).toJson();
}

class ClaimValidator {
  const ClaimValidator();

  ClaimCheckResult check({
    required final String claim,
    required final String evidenceText,
  }) {
    final normalizedClaim = claim.trim();
    final text = evidenceText.toLowerCase();
    final diagnostics = <String>[];
    final nonClaims = <String>[
      'Claim checks are negative gates; they do not accept or award steward status.',
      'A not_rejected result only means this negative gate did not find obvious overclaim terms.',
      'This check does not prove consciousness, final authority, or H4/H5 behavior.',
    ];

    if (!_supportedClaims.contains(normalizedClaim)) {
      return ClaimCheckResult(
        claim: normalizedClaim,
        valid: false,
        diagnostics: ['unsupported claim: $normalizedClaim'],
        nonClaims: nonClaims,
      );
    }

    switch (normalizedClaim) {
      case 'stewardship_protocol':
        _requireAll(text, diagnostics, [
          'stewardship_protocol',
          'mode',
          'memory',
          'handoff',
          'evidence',
          'non-claims',
        ]);
      case 'steward_presence':
        _requireAll(text, diagnostics, [
          'steward-presence',
          'mode event',
          'intent',
          'evidence bar',
          'non-claims',
        ]);
      case 'proven_repo_steward':
        _requireAll(text, diagnostics, [
          'with continuity',
          'without continuity',
          'decisions',
          'handoffs',
          'boundary',
          'non-claims',
        ]);
      case 'sub_steward':
        _requireAll(text, diagnostics, [
          'root steward',
          'temporary lenses',
          'repeated',
          'distinct continuity',
          'boundary',
          'non-claims',
        ]);
      case 'harness_ready':
        _requireAll(text, diagnostics, [
          'doctor',
          'actions list',
          'action inspect',
          'probe',
          'benchmark',
          'result: "pass"',
        ]);
        if (text.contains('durability_blocked') || text.contains('blocked')) {
          diagnostics.add(
            'harness_ready cannot pass from blocked or durability_blocked evidence.',
          );
        }
      case 'fully_adopted':
        _requireAll(text, diagnostics, [
          'held_out_benchmarks',
          'repeated',
          'hot_path_claim',
          'observed_effect',
          'product_impact_line',
          'non-claims',
        ]);
    }

    return ClaimCheckResult(
      claim: normalizedClaim,
      valid: diagnostics.isEmpty,
      diagnostics: diagnostics,
      nonClaims: nonClaims,
    );
  }
}

void _requireAll(
  final String text,
  final List<String> diagnostics,
  final List<String> requiredTerms,
) {
  for (final term in requiredTerms) {
    if (!text.contains(term.toLowerCase())) {
      diagnostics.add('missing evidence term: $term');
    }
  }
}
