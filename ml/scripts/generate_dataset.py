import csv
import os
import random

def generate_datasets():
    base_dir = os.path.join(os.path.dirname(__file__), '..')
    dataset_dir = os.path.join(base_dir, 'dataset')
    os.makedirs(dataset_dir, exist_ok=True)
    os.makedirs(os.path.join(base_dir, 'reports'), exist_ok=True)
    os.makedirs(os.path.join(base_dir, 'model'), exist_ok=True)

    # ==========================================
    # 1. REMINDERS (Direct requests to be reminded)
    # ==========================================
    reminder_prefixes = [
        "remind me to", "please remind me to", "set a reminder to", "don't let me forget to",
        "dont let me forget to", "i need a reminder to", "notify me to", "alert me to",
        "schedule a reminder to", "remember to", "kindly remind me to", "make sure i",
        "warn me to", "remind me at", "remind me tomorrow to", "remind me in",
        "alarm me to", "create a reminder for", "set an alarm for", "remind me about",
        "ping me to", "remind me next week to", "put a reminder to"
    ]
    reminder_actions = [
        "call mom", "take my medicine", "pay electricity bill", "submit assignment",
        "attend team standup", "drink water", "pick up groceries", "send project report",
        "buy milk and bread", "book doctor appointment", "feed the cat", "stretch and exercise",
        "renew car insurance", "reply to client email", "check oven", "turn off the heater",
        "file tax returns", "pay credit card bill", "meet rahul at cafe", "call dad",
        "take blood pressure tablet", "pick kids from school", "order dinner", "charge laptop",
        "review pull request", "wash clothes", "take vitamins", "pack luggage", "fill petrol",
        "clean kitchen", "pay rent", "water the plants", "attend webinar", "check mailbox",
        "call my mother", "submit the project report to professor ahmed", "check the washing machine",
        "go to the gym", "study for my exam", "buy vegetables", "transfer money to brother",
        "call sir", "take bp tablet after lunch", "attend zoom meeting", "finish presentation slides"
    ]
    reminder_times = [
        "at 7 pm", "tomorrow morning", "in 10 minutes", "in 2 hours", "at 9 am",
        "tonight at 8", "this evening", "tomorrow at 5", "next monday", "after 30 minutes",
        "at 6:30 am", "on sunday afternoon", "at noon", "every day at 8 am",
        "every monday", "every week", "daily at 10 pm", "tomorrow", "today evening at 6",
        "tomorrow at 6 pm", "tomorrow at 7 pm", "in 20 minutes", "next friday at 11",
        "day after tomorrow at 4 pm", "at 17:30", "around 7 pm", "every weekday at 9 am",
        "at 8:5 pm today", "at 8 :5 pm today", "at 8 5 pm today", "at 8:05 pm today",
        "8 :5 pm today", "8:5 pm today", "8 5 pm today", "8:05 pm today", "8 :5 am today",
        "today at 8:5 pm", "today at 8 :5 pm", "tomorrow at 8:5 pm", "tomorrow at 8 :5 pm",
        "at 7:5 pm today", "at 9:5 pm today", "at 6:5 am today", "at 10:5 am today",
        "at 8:05 pm", "at 8:05 p.m.", "at 8 p.m.", "at 8:00 p.m.", "at 8 pm", "at 8:00 pm",
        "at 8 tonight", "at 8 in the evening", "at 8:05 tonight", "at 8:05 in the evening",
        "at 7:00 pm", "at 7:30 pm", "at 9:00 pm", "at 9:30 pm", "at 10:00 pm",
        "at 8:05 am", "at 8:05 a.m.", "at 8 a.m.", "at 8 in the morning"
    ]

    reminders = []
    # Prefix + Action + Time
    for prefix in reminder_prefixes:
        for action in random.sample(reminder_actions, 18):
            time = random.choice(reminder_times)
            reminders.append(f"{prefix} {action} {time}")
            reminders.append(f"{prefix} {action} {time}".lower().replace(",", "").replace(".", ""))

    # Explicit Command/Urgent phrasing without prefix
    direct_commands = [
        "tomorrow at 7 pm call mom",
        "call mom tomorrow at 7 pm",
        "remind me at 8:05 pm to call mom",
        "remind me at 8:05 p.m. to take pills",
        "remind me at 8 p.m. to meet alex",
        "remind me at 8 tonight to call john",
        "remind me at 8 in the morning to exercise",
        "call mom at 8:05 pm",
        "call mom at 8:05 p.m.",
        "call mom at 8 p.m.",
        "take medicine at 8:05 pm",
        "take medicine at 8:05 p.m.",
        "call mom tomorrow",
        "i have to call mom tomorrow",
        "i need to call mom tomorrow",
        "don't let me forget to call mom tomorrow",
        "next monday at 9 am remind me to submit the report",
        "remind me in 20 minutes to check the oven",
        "remind me in two hours",
        "remind me at 7",
        "remind me tomorrow morning",
        "remind me tonight",
        "every monday at 9",
        "every weekend remind me to call home",
        "remind me next friday about my exam",
        "remind me tomorrow at 6 pm to submit the report",
        "at 5 pm tomorrow i need to go to the doctor",
        "please remind me in two hours to check the washing machine",
        "remind me tmrw 6pm call sir",
        "don't let me forget that i have a meeting tomorrow",
        "dont let me forget that i have a meeting tomorrow",
        "remind me tomorrow that it is my sister's birthday",
        "i need to study for my exam tomorrow",
        "need to submit assignment tomorrow morning",
        "must take tablet tonight at 9 pm",
        "pakka remind me at 8 pm to call client",
        "remind me to give money to maid tomorrow",
        "set reminder for tomorrow 10 am meeting",
        "remind me to buy groceries tomorrow",
        "remind me in 30 minutes to check the oven",
        "every monday at 9 am remind me about my meeting",
        "8 :5 pm today",
        "8:5 pm today",
        "8 5 pm today",
        "8:05 pm today",
        "8 :5 am today",
        "8:5 am today",
        "at 8 :5 pm today",
        "at 8:5 pm today",
        "at 8 5 pm today",
        "call mom at 8 :5 pm today",
        "call mom at 8:5 pm today",
        "call mom 8 :5 pm today",
        "call mom 8:5 pm today",
        "take medicine at 8 :5 pm today",
        "take medicine 8:5 pm today",
        "take tablet at 8 :5 pm today",
        "take tablet 8 :5 pm today",
        "meeting at 8 :5 pm today",
        "meeting at 8:5 pm today",
        "check oven at 8 :5 pm today",
        "drink water at 8 :5 pm today",
        "pay bill at 8 :5 pm today",
        "study at 8 :5 pm today",
        "gym at 8 :5 pm today",
        "dinner at 8 :5 pm today"
    ]
    reminders.extend(direct_commands * 14)

    indian_english_reminders = [
        "remind me tomorrow morning na",
        "please to remind me for calling doctor",
        "don't forget to take tablet after lunch",
        "put reminder for tomorrow 10 am meeting",
        "remind me to give money to maid tomorrow",
        "set alarm for train reaching station",
        "alert me when 5 minutes are left",
        "remind me to buy vegetables today evening",
        "remind me to transfer money to brother",
        "pakka remind me at 8 pm"
    ]
    reminders.extend(indian_english_reminders * 15)

    random.shuffle(reminders)
    reminders = reminders[:1400]

    with open(os.path.join(dataset_dir, 'reminder.csv'), 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['text', 'label', 'source'])
        for r in reminders:
            writer.writerow([r, 'reminder', 'synthetic_voice_text'])

    # ==========================================
    # 2. DIARY SAMPLES (Past reflections, feelings, daily logs)
    # ==========================================
    diary_starters = [
        "today i", "today was", "i feel", "i felt", "my day was", "i am feeling",
        "reflected on", "spent the day", "journal:", "dear diary", "grateful for",
        "had an interesting conversation with", "thinking about", "finished reading",
        "went for a long walk and", "proud of myself for", "struggling with",
        "learned that", "realized that", "it was a quiet day and", "this morning i",
        "tonight i am sitting and thinking about", "looking back on today", "personal log:",
        "today went by so fast and i", "what a day", "what a tiring day today",
        "had a great day at college", "today was exhausting because", "today i visited my",
        "today i completed my", "i was nervous about my"
    ]
    diary_reflections = [
        "productive and accomplished all my planned tasks",
        "a bit overwhelming with back to back meetings",
        "peaceful spending quality time with family",
        "full of surprises and new learnings about architecture",
        "tiring but deeply rewarding after releasing the project",
        "really happy because we made great progress",
        "a little anxious about the upcoming interview but preparing well",
        "grateful for the support from my colleagues and mentors",
        "enjoyed cooking dinner and reading two chapters of my favorite novel",
        "meditated in the morning and noticed better focus throughout the afternoon",
        "felt energized after morning run around the park",
        "spent time organizing my desk and thoughts for the new week",
        "a nostalgic evening remembering old college memories",
        "feeling calm and ready to take on tomorrow's challenges",
        "inspired after reading an insightful essay on mindfulness",
        "content with how simply today unfolded with loved ones",
        "disappointed with my procrastination today but tomorrow is a fresh start",
        "full of gratitude for good health and simple joys",
        "went to college today and met my project guide",
        "exhausting because i had three meetings",
        "visited my grandparents and enjoyed lunch with them",
        "really productive day at work",
        "nervous about my presentation today but it went well",
        "completed my project finally feeling so relieved",
        "met my old friend at the cafe caught up after three years"
    ]
    diary_daily_logs = [
        "today i went to college today and met my project guide",
        "today was exhausting because i had three meetings",
        "today i visited my grandparents",
        "i had a really productive day",
        "i was nervous about my presentation today",
        "today i completed my project",
        "today was a difficult day",
        "today was my mother's birthday and we celebrated with cake",
        "i had a meeting today with the client",
        "today i met my old friend at the cafe",
        "had a great day at college learning flutter",
        "what a tiring day today spent hours debugging code",
        "woke up early and had black coffee while listening to rain",
        "had lunch with an old friend at the corner cafe caught up on life",
        "completed module 2 of machine learning course feeling proud",
        "evening was serene watched the sunset from the balcony",
        "journal entry today was all about finding balance between work and rest",
        "celebrated team member's birthday today lots of laughs and good food",
        "worked on the flutter project all afternoon solved a tricky notification bug",
        "cleaned my bookshelf arranged all novels chronologically",
        "made homemade pasta for dinner turned out surprisingly delicious",
        "went star gazing on the terrace after a long stressful week",
        "visited the botanical garden in the morning the flowers were in full bloom",
        "wrote in my journal about personal goals for the upcoming quarter",
        "today i remembered that i have a meeting tomorrow and felt relieved i prepared"
    ]

    diaries = []
    for starter in diary_starters:
        for refl in random.sample(diary_reflections, 12):
            diaries.append(f"{starter} {refl}")
            diaries.append(f"{starter.capitalize()} {refl}.".lower())

    for log in diary_daily_logs:
        diaries.append(log)
        diaries.append(f"Diary: {log}")
        diaries.append(f"Today {log}")
        diaries.append(f"Journal: {log}")
        diaries.append(log.lower().replace(",", "").replace(".", ""))

    diaries.extend(diary_daily_logs * 12)
    random.shuffle(diaries)
    diaries = diaries[:1400]

    with open(os.path.join(dataset_dir, 'diary.csv'), 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['text', 'label', 'source'])
        for d in diaries:
            writer.writerow([d, 'diary', 'synthetic_journal_voice'])

    # ==========================================
    # 3. FUTURE EVENT IN DIARY (Diary logs describing future events - NOT explicit reminders)
    # ==========================================
    future_events = [
        "tomorrow is my mother's birthday",
        "tomorrow is my sister's birthday",
        "i have an exam tomorrow",
        "i have a meeting tomorrow",
        "my exam is on friday",
        "my exam is next friday",
        "next monday is my project review",
        "i have a college presentation on 25 september at 10 am",
        "presentation is scheduled for next wednesday at 2 pm",
        "flight to mumbai is on saturday at 6 am",
        "sister wedding is on 15th november",
        "team annual gathering is scheduled for next month",
        "doctor appointment is on thursday at 4 pm",
        "interview scheduled for next friday at 11",
        "client demo is coming up on tuesday morning",
        "project submission deadline is on 30th",
        "parents anniversary is next sunday",
        "semester exams begin on monday",
        "blood test scheduled for tomorrow at 8 am",
        "dentist visit scheduled for next week",
        "tomorrow morning is my thesis defense",
        "tomorrow evening is the farewell party"
    ]
    future_event_samples = []
    for fe in future_events:
        future_event_samples.append(fe)
        future_event_samples.append(f"just noted: {fe}")
        future_event_samples.append(f"remembering that {fe}")
        future_event_samples.append(f"journal note: {fe}")
        future_event_samples.append(f"calendar check: {fe}")
        future_event_samples.append(fe.lower())

    future_event_samples = future_event_samples * 25
    random.shuffle(future_event_samples)
    future_event_samples = future_event_samples[:1000]

    # ==========================================
    # 4. OFF-TOPIC INPUTS (General AI queries, coding tasks, trivia)
    # ==========================================
    off_topic_queries = [
        "give me a python program to reverse a string",
        "give me code for binary search",
        "give me a python program to sort an array",
        "what is machine learning",
        "what is the capital of france",
        "how to calculate compound interest",
        "write an essay on global warming",
        "solve 25 multiplied by 48",
        "what is the difference between sql and nosql",
        "explain quantum computing in simple terms",
        "write a javascript function to debounce",
        "how does flutter render widgets",
        "who wrote romeo and juliet",
        "what is the speed of light",
        "translate hello to spanish",
        "how to cook pasta",
        "what is the formula for pythagorean theorem",
        "give me a recipe for chocolate cake",
        "generate a poem about autumn",
        "explain recursion with an example",
        "write a bash script to backup database",
        "what is the tallest mountain in the world"
    ]
    off_topic_samples = []
    for ot in off_topic_queries:
        off_topic_samples.append(ot)
        off_topic_samples.append(f"hey {ot}")
        off_topic_samples.append(f"can you {ot}")
        off_topic_samples.append(f"please {ot}")
        off_topic_samples.append(ot.lower())

    off_topic_samples = off_topic_samples * 25
    random.shuffle(off_topic_samples)
    off_topic_samples = off_topic_samples[:1000]

    # ==========================================
    # 5. AMBIGUOUS SAMPLES (Vague, undetermined statements)
    # ==========================================
    ambiguous_templates = [
        "tomorrow i need to call mom", "maybe i should read book tonight",
        "i have to finish the report soon", "thinking of going to gym tomorrow",
        "might visit the grocery store later", "probably need to buy milk",
        "client meeting tomorrow afternoon", "dentist appointment next week",
        "car service due sometime soon", "planning to start diet next monday",
        "i wonder if i should call rohit tomorrow", "need to look into plane tickets",
        "assignment submission is on friday", "electricity bill came today",
        "should clean the room this weekend", "need new running shoes",
        "doctor asked to check bp regularly", "meeting scheduled for 3 pm",
        "presentation on monday", "have to wake up early tomorrow",
        "remind me at 7", "remind me tomorrow morning", "remind me monday"
    ]
    ambiguous_modifiers = [
        "", "maybe", "not sure if", "i guess", "probably", "sometime", "just thinking",
        "perhaps", "wondering if", "might be", "eventually"
    ]

    ambiguous = []
    for t in ambiguous_templates:
        for m in ambiguous_modifiers:
            text = f"{m} {t}".strip() if m else t
            ambiguous.append(text)
            ambiguous.append(text.lower())

    ambiguous = list(set(ambiguous))
    while len(ambiguous) < 1200:
        base = random.choice(ambiguous_templates)
        extra = random.choice(["perhaps", "sometime soon", "eventually", "wondering about it", "soon"])
        ambiguous.append(f"{base} {extra}")

    random.shuffle(ambiguous)
    ambiguous = ambiguous[:1200]

    with open(os.path.join(dataset_dir, 'ambiguous.csv'), 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['text', 'label', 'source'])
        for a in ambiguous:
            writer.writerow([a, 'ambiguous', 'synthetic_edge_cases'])

    with open(os.path.join(dataset_dir, 'future_event.csv'), 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['text', 'label', 'source'])
        for fe in future_event_samples:
            writer.writerow([fe, 'future_event', 'diary_calendar_commitment'])

    with open(os.path.join(dataset_dir, 'off_topic.csv'), 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['text', 'label', 'source'])
        for ot in off_topic_samples:
            writer.writerow([ot, 'off_topic', 'general_ai_queries'])

    print("Dataset v2 generated successfully:")
    print(f"- Reminders:     {len(reminders)}")
    print(f"- Diaries:       {len(diaries)}")
    print(f"- Ambiguous:     {len(ambiguous)}")
    print(f"- Future Events: {len(future_event_samples)}")
    print(f"- Off-Topic:     {len(off_topic_samples)}")

if __name__ == '__main__':
    generate_datasets()
