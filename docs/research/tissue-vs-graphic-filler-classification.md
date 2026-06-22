# Tissue vs Graphic Paper — Filler 수요 분류 기준 (URM paper_mill_profile)

> 작성: 2026-06-18 · 용도: `app.paper_mill_profile` 및 satellite PCC/GCC 공급관계 매핑 시 mill을 filler 수요 기준으로 분류하기 위한 도메인 규칙. org `b25de8f2-1020-482f-9012-183f63883169`.

## 1. 핵심 원칙 (One-liner)

**Tissue mill ≠ filler 대형 수요처.** Toilet paper / kitchen towel / facial tissue / napkin을 만드는 tissue mill은 filler(PCC/GCC)를 거의 쓰지 않거나 극소량만 사용한다. 따라서 on-site satellite PCC/GCC 공급관계 매핑에서 **순수 tissue mill은 후보에서 제외하거나 `low/none` filler 등급으로 분류**한다. Satellite PCC/GCC plant는 압도적으로 **graphic paper(특히 woodfree 인쇄·필기용지)** 와 일부 **coated board / carton board** mill에 집중된다.

## 2. 왜 tissue는 filler를 안 쓰는가 (기술 근거)

| 항목 | Graphic paper (woodfree) | Tissue |
|---|---|---|
| 목표 물성 | 백색도, 불투명도, 평활도, 인쇄성, 비용절감 | 부드러움(softness), 흡수성(absorbency), 벌크(bulk), 습윤강도 |
| Filler 역할 | 섬유 대체(원가↓) + 광학 특성↑ | **유해** — 결합 약화, 흡수성·부드러움 저하 |
| 전형적 ash 함량 | 10–30%+ | ~0–2% (사실상 unfilled) |
| 결론 | PCC/GCC 대량 소비 | filler 거의 미사용 |

Filler는 섬유 간 결합을 방해해 인장강도를 떨어뜨린다. Graphic paper는 표면 사이징·코팅으로 이를 보완하지만, tissue는 애초에 **낮은 결합·높은 벌크**가 제품 본질이라 보완이 아니라 손해다. 부드러움과 흡수성이 핵심 판매 포인트이므로 filler를 넣을 유인이 없다.

## 3. 분류 의사결정 트리

```
mill.product_category ?
├─ tissue / toilet / towel / facial / napkin / AFH-tissue
│     └─ filler_demand = 'none_or_trace'   → satellite PCC/GCC 후보에서 제외
├─ woodfree printing & writing / uncoated freesheet / copy paper
│     └─ filler_demand = 'high'            → on-site PCC 1순위 후보
├─ coated paper (LWC / coated woodfree)
│     └─ filler_demand = 'high' (+ coating GCC) → PCC + coating-grade GCC 후보
├─ carton board / folding boxboard / coated board
│     └─ filler_demand = 'medium'          → 일부 satellite 후보
├─ newsprint / mechanical
│     └─ filler_demand = 'low'             → 보통 제외
└─ containerboard / kraft / packaging (unbleached)
      └─ filler_demand = 'none_or_low'     → 제외
```

## 4. 데이터 적용 규칙 (paper_mill_profile)

1. `paper_mill_profile`에 `filler_demand` 분류 시 위 트리를 사용. tissue 계열은 일괄 `none_or_trace`.
2. **integrated tissue mill**(자체 pulp 생산)이라도 filler 결론은 동일 — pulp 통합 여부와 filler 수요는 무관.
3. satellite PCC/GCC supply link를 tissue mill에 연결하려는 후보가 나오면 **evidence_level 재검토**. 거의 항상 오분류이거나, 같은 사업장 내 별도 graphic/board 라인 때문일 가능성.
4. 기존 도메인 규칙과 일관: *FulFill® technology ≠ on-site satellite*, *mill activity ≠ satellite activity*. tissue 케이스도 같은 맥락 — "그 mill이 종이를 만든다"는 사실이 "그 mill이 filler를 소비한다"를 의미하지 않는다.

## 5. Tissue mill에서 그래도 봐야 할 것 (false-negative 방지)

- **복합 사업장**: 한 site에 tissue 라인 + graphic/board 라인이 공존하면, filler 수요는 graphic/board 라인에서 발생한다. site 단위가 아니라 **machine/line 단위**로 분류.
- **specialty tissue / 특수지**: 일부 specialty(예: 일부 wrapping, 특정 코팅 tissue)는 예외적으로 소량 mineral을 쓸 수 있으나 satellite plant를 정당화할 규모는 아님.
- **non-wood tissue (bamboo/bagasse)**: 섬유 원료만 다를 뿐 filler 결론은 동일(none_or_trace).

## 6. 원료 가격 참고 (tissue mill 공급사슬 식별 보조)

Tissue mill은 filler가 아니라 **market pulp(또는 자체 pulp) + 재생/대체섬유**가 핵심 투입재다. supply-link 매핑 시 tissue mill의 진짜 카운터파티는 PCC/GCC 공급사가 아니라 pulp 공급사임을 기억.

| 섬유 | 대표 가격대 (mid-2025~Q1 2026) | 비고 |
|---|---|---|
| NBSK (virgin softwood) | $690–760/t (China net), $730–745/t (EU spot) | 강도·ply용 장섬유 |
| BHKP/BEK (virgin hardwood) | $497–585/t (China net) | 부드러움용 단섬유 |
| Recovered paper / 재생펄프 | $253–480/t (회수지), DIP 표준등급은 virgin 대비 10–30%↓ | 에너지 40–70%↓ |
| 식품등급 재생펄프 | virgin 대비 5–20%↑ | 탈오염·안전검증 비용 |
| Bamboo chemical pulp | $700–1,100/t (bulk); 수입 프리미엄 시 $1,100–1,550/t | 대체섬유 |
| Bagasse pulp | 원료비 저렴; bleached가 unbleached 대비 +20–25% | 농업부산물, 지역성 강함 |

> pulp는 tissue 제조원가의 ~30%(통상), non-integrated mill은 50–70%까지. 비통합 mill이 글로벌 capacity의 ~85%. 비통합 tissue mill 식별에는 FisherSolve 류 플랫폼이 업계 표준.

## 7. 요약

- tissue = filler 비수요. satellite PCC/GCC 매핑에서 **제외 기본값**.
- filler satellite는 **woodfree graphic + coated board**가 본진.
- 분류는 site가 아니라 **line 단위**, integrated 여부와 무관.
- tissue mill supply-link의 본질 카운터파티는 **pulp/대체섬유 공급사**.
