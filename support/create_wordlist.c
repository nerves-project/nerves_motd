// SPDX-FileCopyrightText: 2026 Frank Hunleth
//
// SPDX-License-Identifier: Apache-2.0
//
// create_wordlist.c
//
// This is a copy/paste of the fwup word generator code that creates the
// `word34567.txt` file used by the NervesMOTD tests.
//
// See https://github.com/fwup-home/fwup/blob/4155d0f5bc495c6cb5041a228bbfd873f1e532ed/src/util.c#L628-L694
//
// There shouldn't be a need to run this unless something changes with how fwup
// generates nicknames.
//
// To build and run:
// $ gcc -o create_wordlist create_wordlist.c
// $ ./create_wordlist

#include <stdio.h>
#include <stdlib.h>
#include <err.h>

static const char word34567_words[] = \
    "act" "able" "about" "absent" "abandon" \
    "add" "away" "aisle" "advice" "address" \
    "aim" "best" "anger" "annual" "analyst" \
    "all" "bone" "armor" "assume" "apology" \
    "arm" "cake" "beach" "barrel" "average" \
    "ask" "chat" "bless" "bitter" "bargain" \
    "bar" "club" "brick" "bronze" "blanket" \
    "bid" "corn" "cabin" "camera" "capital" \
    "boy" "dash" "chalk" "casual" "certain" \
    "can" "dice" "civil" "cherry" "coconut" \
    "cat" "drip" "cloud" "column" "conduct" \
    "cup" "east" "craft" "credit" "crucial" \
    "day" "fall" "curve" "debris" "cushion" \
    "dry" "fine" "dream" "depend" "despair" \
    "egg" "foil" "earth" "dinner" "dilemma" \
    "era" "gain" "entry" "dragon" "dynamic" \
    "fan" "glad" "exist" "energy" "emotion" \
    "few" "grit" "field" "estate" "essence" \
    "fix" "head" "focus" "expire" "exhibit" \
    "fog" "hood" "gauge" "finger" "fatigue" \
    "fox" "idea" "glove" "fossil" "forward" \
    "gap" "jump" "grunt" "garlic" "genuine" \
    "hat" "kiwi" "hello" "guitar" "gravity" \
    "hip" "lazy" "inner" "horror" "illness" \
    "ice" "link" "labor" "indoor" "initial" \
    "job" "loop" "light" "invest" "jealous" \
    "key" "math" "maple" "laptop" "lecture" \
    "kid" "mind" "mimic" "lonely" "lottery" \
    "lab" "name" "nasty" "margin" "mention" \
    "mad" "nose" "offer" "middle" "monitor" \
    "mix" "open" "owner" "motion" "network" \
    "net" "pass" "piano" "nephew" "observe" \
    "nut" "plug" "power" "online" "ostrich" \
    "oak" "pulp" "purse" "palace" "peasant" \
    "oil" "ramp" "ready" "phrase" "popular" \
    "one" "ring" "round" "praise" "present" \
    "pen" "safe" "scrap" "reason" "program" \
    "pig" "seed" "shock" "relief" "pudding" \
    "raw" "sign" "skill" "resist" "raccoon" \
    "rug" "slot" "snack" "ripple" "release" \
    "run" "soon" "spawn" "salute" "satisfy" \
    "say" "step" "spray" "select" "session" \
    "shy" "tape" "still" "silver" "slender" \
    "spy" "text" "super" "sphere" "stomach" \
    "tag" "tiny" "table" "street" "supreme" \
    "tip" "trip" "tired" "symbol" "thunder" \
    "toe" "undo" "trade" "ticket" "trigger" \
    "toy" "visa" "truth" "travel" "uncover" \
    "two" "wasp" "vague" "unfold" "utility" \
    "van" "wild" "vivid" "valley" "vibrant" \
    "web" "yard" "zebra" "voyage" "weather" \
    "zoo" \
    "";

static void word34567(int index, const char **word, int *len)
{
    // Each row has 5 words with lengths 3 to 7. That's 25 letters per row.
    // The offset of the mth word in each row is 0, 3, 7, 12, 18, but this
    // can be computed as m * (m + 5) / 2.
    int m = index % 5;
    *len = m + 3;
    *word = &word34567_words[(index / 5) * 25 + m * (m + 5) / 2];
}

int main(int argc, char *argv[])
{
    FILE *fp = fopen("../test/fixture/word34567.txt", "w");
    if (!fp)
        err(EXIT_FAILURE, "fopen word34567.txt");

    for (int i = 0; i < 256; i++) {
        const char *word;
        int len;
        word34567(i, &word, &len);
        fprintf(fp, "%.*s\n", len, word);
    }
    fclose(fp);

    printf("Success.\n");
    exit(EXIT_SUCCESS);
}
