//
//  TaxAssistantService.swift
//  TravelNurse
//
//  AI-powered tax assistant for travel nurses
//

import Foundation

/// Service providing AI tax assistance for travel nurses
final class TaxAssistantService: TaxAssistantAI {

    // MARK: - Constants

    /// Maximum message length to prevent DoS from extremely large inputs
    private static let maxMessageLength = 500

    // MARK: - Knowledge Base

    private let knowledgeBase: TaxKnowledgeBase

    init() {
        knowledgeBase = TaxKnowledgeBase()
    }

    // MARK: - TaxAssistantAI

    func sendMessage(_ message: String, context: TaxAssistantContext) async throws -> TaxAssistantResponse {
        // Limit input length to prevent DoS
        let truncatedMessage = String(message.prefix(Self.maxMessageLength))
        let normalizedMessage = truncatedMessage.lowercased()

        // Find matching topics in knowledge base
        let matchedTopics = knowledgeBase.findMatchingTopics(for: normalizedMessage)

        if let bestMatch = matchedTopics.first {
            // Build response with context
            let response = buildResponse(for: bestMatch, context: context, originalMessage: truncatedMessage)
            return response
        }

        // If no match found, provide general guidance
        return TaxAssistantResponse(
            message: "I'm not sure about that specific question, but I can help with travel nurse tax topics like:\n\n" +
                    "- Tax home requirements\n" +
                    "- Stipend taxation\n" +
                    "- Deductible expenses\n" +
                    "- Multi-state taxes\n" +
                    "- Quarterly estimated payments\n\n" +
                    "What would you like to know more about?",
            suggestions: ["Tell me about tax home", "What expenses can I deduct?", "How do stipends work?"],
            relatedTopics: ["Tax Home", "Deductions", "Stipends"],
            disclaimer: standardDisclaimer,
            confidence: 0.5
        )
    }

    func getTaxTips(for context: TaxAssistantContext) async throws -> [TaxTip] {
        var tips: [TaxTip] = []

        // Tax home tips
        if context.taxHomeState == nil {
            tips.append(TaxTip(
                title: "Set Up Your Tax Home",
                description: "Establishing a tax home is crucial for receiving tax-free stipends. Add your permanent address in Settings to ensure compliance.",
                category: .compliance,
                priority: .high
            ))
        }

        // Quarterly payment reminder
        let month = Calendar.current.component(.month, from: Date())
        if [3, 5, 8, 12].contains(month) {
            let nextDue = getNextQuarterlyDueDate()
            tips.append(TaxTip(
                title: "Quarterly Payment Coming Up",
                description: "Your next estimated tax payment is due \(nextDue). Make sure you've saved enough to cover your tax liability.",
                category: .planning,
                priority: .high
            ))
        }

        // Deduction opportunities
        if context.ytdDeductions < context.ytdIncome * 0.1 {
            tips.append(TaxTip(
                title: "Track More Deductions",
                description: "Your tracked deductions seem low compared to income. Common overlooked deductions include: scrubs, CEU courses, professional memberships, and license fees.",
                category: .deduction,
                priority: .medium,
                potentialSavings: context.ytdIncome * 0.05 * 0.25
            ))
        }

        // Multi-state warning
        if context.hasMultipleStates {
            tips.append(TaxTip(
                title: "Multi-State Filing Required",
                description: "You've worked in multiple states this year. You may need to file tax returns in each state where you earned income.",
                category: .warning,
                priority: .high
            ))
        }

        // Mileage tracking
        tips.append(TaxTip(
            title: "Don't Forget Mileage",
            description: "At $0.67/mile (2024 rate), a 20-mile round trip to work saves you about $3.35 in taxes per day. Track all work-related trips!",
            category: .deduction,
            priority: .medium,
            potentialSavings: Decimal(string: "2500") // Estimated annual savings
        ))

        return tips.sorted { $0.priority > $1.priority }
    }

    // MARK: - Private Methods

    private func buildResponse(for topic: TaxTopic, context: TaxAssistantContext, originalMessage: String) -> TaxAssistantResponse {
        var message = topic.answer

        // Personalize response with context
        if let state = context.taxHomeState {
            message = message.replacingOccurrences(of: "{state}", with: state.rawValue)
        }

        if context.ytdIncome > 0 {
            let formattedIncome = formatCurrency(context.ytdIncome)
            message = message.replacingOccurrences(of: "{ytdIncome}", with: formattedIncome)
        }

        // Add related suggestions
        let suggestions = topic.followUpQuestions

        return TaxAssistantResponse(
            message: message,
            suggestions: suggestions,
            relatedTopics: topic.relatedTopics,
            disclaimer: topic.requiresDisclaimer ? standardDisclaimer : nil,
            confidence: topic.confidence
        )
    }

    private var standardDisclaimer: String {
        "This is general information only and not tax advice. Please consult a tax professional for your specific situation."
    }

    private func getNextQuarterlyDueDate() -> String {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        let dueDates: [(month: Int, day: Int, label: String)] = [
            (4, 15, "April 15"),
            (6, 15, "June 15"),
            (9, 15, "September 15"),
            (1, 15, "January 15")
        ]

        for dueDate in dueDates {
            var components = DateComponents()
            components.year = dueDate.month == 1 ? year + 1 : year
            components.month = dueDate.month
            components.day = dueDate.day

            if let date = calendar.date(from: components), date > now {
                return dueDate.label
            }
        }

        return "April 15"
    }

    private func formatCurrency(_ value: Decimal) -> String {
        TNFormatters.currency(value)
    }
}

// MARK: - Tax Knowledge Base

private struct TaxKnowledgeBase {

    let topics: [TaxTopic]

    init() {
        topics = Self.buildKnowledgeBase()
    }

    func findMatchingTopics(for query: String) -> [TaxTopic] {
        let queryWords = Set(query.lowercased().components(separatedBy: .whitespaces))

        var scoredTopics: [(TaxTopic, Double)] = []

        for topic in topics {
            var score = 0.0

            // Check keywords
            for keyword in topic.keywords {
                if queryWords.contains(keyword) {
                    score += 0.3
                }
                if query.contains(keyword) {
                    score += 0.2
                }
            }

            // Check question patterns
            for pattern in topic.questionPatterns {
                if query.contains(pattern) {
                    score += 0.5
                }
            }

            if score > 0 {
                scoredTopics.append((topic, score))
            }
        }

        return scoredTopics.sorted { $0.1 > $1.1 }.map { $0.0 }
    }

    // MARK: - Knowledge Base Content

    private static func buildKnowledgeBase() -> [TaxTopic] {
        [
            // Tax Home
            TaxTopic(
                id: "tax-home",
                keywords: ["tax home", "home", "permanent", "residence", "address", "domicile"],
                questionPatterns: ["what is tax home", "tax home requirement", "need tax home", "establish tax home", "maintain tax home"],
                answer: """
                    **Tax Home for Travel Nurses**

                    Your tax home is your regular place of business, regardless of where you live. For travel nurses, maintaining a valid tax home is ESSENTIAL for receiving tax-free stipends.

                    **Requirements:**
                    1. **Duplicate Expenses**: You must pay for housing in TWO places - your tax home AND your assignment location
                    2. **Regular Returns**: Return to your tax home regularly (at least once a year)
                    3. **Ongoing Ties**: Maintain ties like voter registration, driver's license, car registration
                    4. **Work History**: Work some shifts near your tax home (ideally 1-2 per month when between assignments)

                    **Without a Valid Tax Home:**
                    All your stipends become TAXABLE income, and you may owe back taxes plus penalties.
                    """,
                followUpQuestions: [
                    "How do I prove my tax home?",
                    "What if I live with family rent-free?",
                    "How often should I return home?"
                ],
                relatedTopics: ["Stipends", "IRS Audits", "Duplicate Expenses"],
                requiresDisclaimer: true,
                confidence: 0.95
            ),

            // Stipends
            TaxTopic(
                id: "stipends",
                keywords: ["stipend", "housing", "meals", "per diem", "tax-free", "non-taxable", "m&ie", "lodging"],
                questionPatterns: ["are stipends taxable", "stipend tax", "housing stipend", "meal stipend", "per diem"],
                answer: """
                    **Travel Nurse Stipends Explained**

                    Stipends (housing, meals, incidentals) are TAX-FREE reimbursements - but only if you meet certain requirements:

                    **Requirements for Tax-Free Stipends:**
                    1. You must have a valid tax home (see tax home requirements)
                    2. You must duplicate expenses (pay for housing in two places)
                    3. Your assignment must be temporary (< 1 year)
                    4. Stipends shouldn't exceed GSA per diem rates for the area

                    **GSA Limits (2024):**
                    - Lodging: Varies by location ($100-$300+/day)
                    - M&IE: $59-$79/day depending on location

                    **What Happens if Stipends Exceed GSA Rates?**
                    Amounts over GSA limits may be considered taxable income by the IRS.

                    **Important**: Stipends are NOT extra pay - they're reimbursements for actual expenses you're incurring.
                    """,
                followUpQuestions: [
                    "What are GSA rates for my area?",
                    "Can I keep leftover stipend money?",
                    "What if my agency pays more than GSA rates?"
                ],
                relatedTopics: ["Tax Home", "GSA Rates", "Agency Pay Packages"],
                requiresDisclaimer: true,
                confidence: 0.95
            ),

            // Deductions
            TaxTopic(
                id: "deductions",
                keywords: ["deduct", "deduction", "write off", "expense", "deductible", "tax break"],
                questionPatterns: ["what can i deduct", "deductible expense", "write off", "tax deduction"],
                answer: """
                    **Common Travel Nurse Tax Deductions**

                    As a travel nurse, you can deduct many work-related expenses:

                    **Always Deductible (100%):**
                    - License fees and renewals
                    - Certification costs (ACLS, BLS, PALS)
                    - CEU courses and conferences
                    - Professional memberships
                    - Malpractice insurance
                    - Scrubs and work shoes
                    - Medical equipment you purchase
                    - Background checks and drug tests

                    **Travel Expenses (if not reimbursed):**
                    - Mileage to/from assignments (67¢/mile in 2024)
                    - Flights to assignment locations
                    - Moving/relocation costs

                    **Partially Deductible:**
                    - Cell phone (work use percentage)
                    - Internet (work use percentage)
                    - Home office (if applicable)

                    **Meals (50% deductible):**
                    - Meals while traveling to assignments
                    - Business meals

                    **Keep Records!** Save all receipts and document business purpose.
                    """,
                followUpQuestions: [
                    "How do I track mileage?",
                    "Can I deduct my housing costs?",
                    "What records do I need to keep?"
                ],
                relatedTopics: ["Mileage", "Receipts", "Record Keeping"],
                requiresDisclaimer: true,
                confidence: 0.9
            ),

            // Quarterly Payments
            TaxTopic(
                id: "quarterly",
                keywords: ["quarterly", "estimated", "payment", "irs", "1040-es", "self-employment"],
                questionPatterns: ["quarterly tax", "estimated tax", "when pay taxes", "quarterly payment"],
                answer: """
                    **Quarterly Estimated Tax Payments**

                    As a travel nurse, taxes aren't always fully withheld from your pay, especially on stipends. You may need to make quarterly payments.

                    **2024 Due Dates:**
                    - Q1: April 15, 2024
                    - Q2: June 15, 2024
                    - Q3: September 15, 2024
                    - Q4: January 15, 2025

                    **How Much to Pay:**
                    A common rule: Set aside 25-30% of your TAXABLE income (hourly pay, not stipends) for taxes.

                    **Components:**
                    - Federal income tax (10-37% depending on bracket)
                    - State income tax (varies, some states have none)
                    - Self-employment tax (if applicable): 15.3%

                    **Avoiding Penalties:**
                    Pay at least 90% of this year's tax OR 100% of last year's tax to avoid underpayment penalties.

                    **Payment Methods:**
                    - IRS Direct Pay (free)
                    - EFTPS (Electronic Federal Tax Payment System)
                    - Check with Form 1040-ES
                    """,
                followUpQuestions: [
                    "How do I calculate my estimated taxes?",
                    "What if I miss a payment?",
                    "Should I adjust my W-4?"
                ],
                relatedTopics: ["Tax Brackets", "Self-Employment Tax", "W-4"],
                requiresDisclaimer: true,
                confidence: 0.9
            ),

            // Multi-State
            TaxTopic(
                id: "multi-state",
                keywords: ["state", "states", "multiple", "multi-state", "file", "resident", "nonresident"],
                questionPatterns: ["multiple states", "state tax", "which state", "file in multiple"],
                answer: """
                    **Multi-State Tax Filing for Travel Nurses**

                    Working in multiple states creates complex tax situations:

                    **General Rules:**
                    1. **Resident State**: You file as a resident in your tax home state
                    2. **Work States**: You file as a nonresident in each state where you worked
                    3. **Tax Credits**: Most states give you credit for taxes paid to other states

                    **No Income Tax States:**
                    Alaska, Florida, Nevada, South Dakota, Texas, Washington, Wyoming, (New Hampshire and Tennessee tax only investment income)

                    **Reciprocity Agreements:**
                    Some neighboring states have agreements - you may only need to file in your resident state.

                    **What You'll Need:**
                    - W-2s showing state wages for each state
                    - Days worked in each state
                    - Your resident state information

                    **Tip**: Keep a calendar of where you worked each day - some states calculate taxes based on days worked there.
                    """,
                followUpQuestions: [
                    "What if my tax home is in a no-tax state?",
                    "How do tax credits work?",
                    "Do I need to file in every state I worked?"
                ],
                relatedTopics: ["State Taxes", "Residency", "Tax Credits"],
                requiresDisclaimer: true,
                confidence: 0.85
            ),

            // Mileage
            TaxTopic(
                id: "mileage",
                keywords: ["mileage", "miles", "driving", "car", "vehicle", "gas", "commute"],
                questionPatterns: ["track mileage", "mileage deduction", "drive to work", "car expense"],
                answer: """
                    **Mileage Deductions for Travel Nurses**

                    **2024 IRS Standard Mileage Rate: $0.67/mile**

                    **What's Deductible:**
                    - Travel between your tax home and assignment locations
                    - Travel between work sites during assignments
                    - Travel for work-related errands (picking up scrubs, etc.)
                    - Travel to professional development/CEU courses

                    **NOT Deductible:**
                    - Regular commute from temporary housing to your assignment facility
                    - Personal errands
                    - Travel that's already reimbursed

                    **How to Track:**
                    Keep a log with: Date, Starting/Ending location, Miles driven, Business purpose

                    **Example Savings:**
                    If you drive 500 miles to an assignment:
                    500 × $0.67 = $335 deduction
                    At 22% tax bracket = ~$74 tax savings

                    **Alternative**: You can use actual expenses (gas, maintenance, insurance) but must keep detailed records.
                    """,
                followUpQuestions: [
                    "What about my daily commute?",
                    "Should I use standard rate or actual expenses?",
                    "How do I log my trips?"
                ],
                relatedTopics: ["Deductions", "Travel Expenses", "Record Keeping"],
                requiresDisclaimer: true,
                confidence: 0.9
            ),

            // Record Keeping
            TaxTopic(
                id: "records",
                keywords: ["record", "receipt", "document", "proof", "audit", "keep", "save"],
                questionPatterns: ["keep records", "save receipts", "what records", "how long keep"],
                answer: """
                    **Record Keeping for Travel Nurses**

                    Good records protect you in an audit and maximize deductions.

                    **What to Keep:**
                    - All W-2s and 1099s
                    - Receipts for deductible expenses
                    - Mileage log
                    - Bank/credit card statements
                    - Copies of licenses and certifications
                    - Assignment contracts
                    - Housing lease/payment records
                    - Proof of tax home (mortgage/rent payments, utility bills)

                    **How Long to Keep:**
                    - Tax returns: 7 years (IRS can audit up to 6 years back in some cases)
                    - Supporting documents: 7 years
                    - Property records: Until 7 years after you sell

                    **Pro Tips:**
                    - Take photos of paper receipts (they fade!)
                    - Use a dedicated credit card for work expenses
                    - Keep a folder for each tax year
                    - Back up digital records to the cloud
                    """,
                followUpQuestions: [
                    "What if I lost a receipt?",
                    "Can I use bank statements instead?",
                    "What triggers an IRS audit?"
                ],
                relatedTopics: ["Audits", "Deductions", "Organization"],
                requiresDisclaimer: true,
                confidence: 0.85
            )
        ]
    }
}

// MARK: - Tax Topic

private struct TaxTopic {
    let id: String
    let keywords: [String]
    let questionPatterns: [String]
    let answer: String
    let followUpQuestions: [String]
    let relatedTopics: [String]
    let requiresDisclaimer: Bool
    let confidence: Double
}
