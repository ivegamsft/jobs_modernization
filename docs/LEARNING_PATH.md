# Learning Path — Jobs Modernization

## How to Use This Repository

This repository demonstrates a **three-phase modernization journey** from legacy .NET Web Forms to modern cloud architecture. Follow this path to learn modernization strategies.

---

## 🎓 For Learners

### Step 1: Understand the Legacy Baseline
**Folder:** `phase1-legacy-baseline/`

Start here to understand what you're modernizing:
1. Review the original code: `phase1-legacy-baseline/appV1-original/`
2. See what it took to make it buildable: `phase1-legacy-baseline/appV1.5-buildable/`
3. Read the code analysis: `phase1-legacy-baseline/docs/CODE_ANALYSIS_REPORT.md`

**Key Question:** Why can't we just deploy this legacy app to the cloud as-is?

---

### Step 2: Learn Lift-and-Shift Migration
**Folder:** `phase2-azure-migration/`

Understand how to migrate without rewriting:
1. Read the migration strategy: `phase2-azure-migration/README.md`
2. Review infrastructure templates: `infrastructure/bicep/`
3. Study deployment documentation: `infrastructure/docs/`

**Key Question:** What changes are needed to host a legacy app on Azure PaaS?

---

### Step 3: Explore Modernization Strategies
**Folder:** `phase3-modernization/`

See how to modernize incrementally:
1. Compare modern .NET API: `phase3-modernization/api-dotnet/`
2. Compare Python alternative: `phase3-modernization/api-python/`
3. Read the React conversion plan: `phase3-modernization/docs/REACT_CONVERSION_PLAN.md`

**Key Question:** How do you modernize without a risky "big bang" rewrite?

---

## 👨‍💼 For Infrastructure Engineers

### Your Focus Areas:
1. **Resource Organization:** [4-Layer RG Strategy](../infrastructure/docs/4LAYER_RG_QUICK_REFERENCE.md)
2. **IaC Templates:** [Bicep Templates](../infrastructure/bicep/)
3. **Deployment:** [Implementation Checklist](../infrastructure/docs/IMPLEMENTATION_CHECKLIST.md)
4. **Troubleshooting:** [Issue Resolution](../infrastructure/docs/THE_ISSUE_AND_FIX.md)

---

## 👩‍💻 For Developers

### Your Focus Areas:
1. **Clean Architecture:** Study `phase3-modernization/api-dotnet/`
2. **API Design:** Compare .NET vs Python implementations
3. **React UI:** Review `phase3-modernization/docs/REACT_CONVERSION_PLAN.md`
4. **Testing:** Check test projects in modern APIs

---

## 📚 Recommended Learning Order

### Week 1: Legacy Understanding
- [ ] Read Phase 1 README
- [ ] Browse appV1-original code
- [ ] Review CODE_ANALYSIS_REPORT.md
- [ ] Understand Web Forms architecture

### Week 2: Azure Migration
- [ ] Read Phase 2 README
- [ ] Study infrastructure templates
- [ ] Deploy to Azure (optional)
- [ ] Learn PaaS vs IaaS tradeoffs

### Week 3: Modernization
- [ ] Read Phase 3 README
- [ ] Compare modern APIs
- [ ] Study clean architecture
- [ ] Plan React UI integration

### Week 4: Hands-On
- [ ] Modify the modern API
- [ ] Add a new endpoint
- [ ] Write tests
- [ ] Deploy changes

---

## 🔑 Key Concepts

1. **Strangler Fig Pattern** — Gradually replace legacy with modern
2. **Lift-and-Shift** — Migrate before modernizing
3. **Clean Architecture** — Separation of concerns
4. **IaC** — Infrastructure as Code for repeatability
5. **PaaS First** — Let Azure manage infrastructure

---

## 🤝 Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for how to contribute to this learning repository.

---

**Remember:** This is a learning repository. Experiment, break things, and learn from mistakes!
