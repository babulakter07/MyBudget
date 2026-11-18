# Brief for v5 module agents (Sprint 10: multi-currency)

Project: `D:\MyProject\MyBudget`. **Read `CLAUDE.md`, `docs/AGENT_BRIEF.md` and `docs/AGENT_BRIEF_V4.md` first; all rules there still apply** (material_ui imports only, integer money, profile isolation, locked commands via `tool/locked.sh`, format only your own paths, never run build_runner/pub get, never kill processes, own only your folders).

## Design (decided; do not redesign)
- The **profile currency** (`financial_profiles.currency_code`, default BDT) is the **base currency**. Accounts, balances, budgets, reports, dashboard, insights, goals, debts are ALL in base currency and are unchanged.
- A transaction may be **entered** in a foreign currency using a **manual exchange rate**. `financial_transactions.amount_minor` is ALWAYS the converted base-currency amount, so every existing query stays correct. Three new nullable columns keep what the user typed: `original_amount_minor`, `original_currency` (3 upper-case letters), `rate_micro` (base major units per 1 foreign major unit x 1,000,000). They are **all NULL or all set**. Only expense and income transactions may carry them (never transfers).
- Invariant: `amount_minor == convertToBaseMinor(originalMinor: original_amount_minor, rateMicro: rate_micro)` (round half up, integers/BigInt only). Reject writes that violate it.
- Rates live in table `exchange_rates` (per profile, unique per currency, `is_active`). Rates are manual; there is NO network access anywhere.
- Out of scope: foreign-currency accounts, rate history, automatic rate fetching.

## Already done by the lead (do not edit)
- Schema is **v5**, code regenerated: table `ExchangeRates/ExchangeRateRow`; new `FinancialTransactions` columns `originalAmountMinor`, `originalCurrency`, `rateMicro`.
- `lib/core/utils/currency.dart`: `knownCurrencies`, `currencySymbol`, `normalizeCurrencyCode`, `parseRateToMicro`, `formatRate`, `convertToBaseMinor`, `formatOriginal`, `rateScale`, `maxRateMicro`.
- `lib/features/currency/{domain,data,providers}`: `ExchangeRate`, `ExchangeRateRepository` (`watchRates`, `getActiveRate`, `upsert`, `setActive`), providers `exchangeRateRepositoryProvider`, `exchangeRatesProvider` (active), `allExchangeRatesProvider`.
- Route `/config/currencies` will be wired by the lead to `ExchangeRatesScreen()` (agent B builds it in `lib/features/currency/presentation/exchange_rates_screen.dart`).
- The base currency code of the active profile is available via `activeProfileProvider` (`profile.currencyCode`).

## Final report
Files, public API, decisions, exact test results, limitations, anything the lead must wire.
