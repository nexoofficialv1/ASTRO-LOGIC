# ASTRO LOGIC — Termux থেকে private GitHub CI শুরু করার চূড়ান্ত পদ্ধতি

বর্তমান development milestone: `v0.78.0+82` — Western Modern Planets & Aspect Pattern Expansion v1।

**এখনই final release tag দেবেন না।** Vastu, Palmistry ও Practice
এখনও Coming Soon; `v*` tag-এর full-scope release gate ইচ্ছাকৃতভাবে এগুলো complete
না হওয়া পর্যন্ত fail করবে। নিচের flow সব module complete হওয়ার পরে ব্যবহার করবেন।

## 1. ফোনে প্রয়োজনীয় package

```bash
pkg update -y
pkg install -y git gh unzip python
termux-setup-storage
gh auth status
```

## 2. Final source ZIP extract

Final milestone-এর ZIP `/sdcard/Download`-এ রেখে:

```bash
rm -rf ~/ASTRO_LOGIC
mkdir -p ~/ASTRO_LOGIC
unzip -o /sdcard/Download/ASTRO_LOGIC_DEVELOPMENT_v082_GITHUB_PUSH_READY.zip -d ~/ASTRO_LOGIC
cd ~/ASTRO_LOGIC
python tool/static_build_readiness_audit.py
python tool/validate_v082_western_modern.py
```

Source-preparation gate pass করলেও এটি runtime build pass নয়।

## 3. Existing private repository-তে প্রথম main push

`nexoofficialv1/ASTRO-LOGIC` repository আগে থেকেই তৈরি থাকলে:

```bash
chmod +x TERMUX_PUSH_EXISTING_REPO.sh
bash TERMUX_PUSH_EXISTING_REPO.sh ASTRO-LOGIC
```

Main push শুধু Android APK CI চালাবে। Windows workflow এই development checkpoint-এ
automatic নয়; সেটি manual dispatch বা final governed tag-এ চলবে। প্রথম Android run-এ
`pubspec.lock` source-এ না থাকলে CI সেটি generate করে evidence artifact-এ রাখবে।

## 4. Android/Windows lock candidate মিলিয়ে commit

দুই platform artifact থেকে `pubspec.lock` ও তার SHA-256 দেখুন। SHA-256 identical
হওয়া আবশ্যক। তারপর সেই exact lock project root-এ রাখুন:

```bash
cp /path/to/tested/pubspec.lock ~/ASTRO_LOGIC/pubspec.lock
cd ~/ASTRO_LOGIC

git add pubspec.lock
git commit -m "Lock tested Flutter dependencies"
git push origin main
```

পরের main CI-তে lock থাকলে `--enforce-lockfile` ব্যবহার হবে। Android ও Windows
দুটো locked build pass করতে হবে।

## 5. Final tag-এর আগে

```bash
cd ~/ASTRO_LOGIC
python tool/final_release_gate.py --require-lock --require-full-scope
```

সব module complete এবং lock present না হলে এটি pass করা উচিত নয়।

`pubspec.yaml`-এ final version যদি `X.Y.Z+N` হয়, tag হবে ঠিক:

```bash
git tag "vX.Y.Z+N"
git push origin "vX.Y.Z+N"
```

Tag push তিনটি gate চালাবে:

- Release Source Gate
- Build Android APK
- Build Windows Desktop

তিনটিই pass করতে হবে।

## 6. Evidence artifacts

Android artifact-এর ভিতরে versioned APK, manifest, SHA-256, analyzer/test/native
logs, dependency graph ও tested lock থাকবে। Windows artifact-এ একই evidence সহ
versioned Windows ZIP থাকবে।

দুটো download করে final bundle বানান:

```bash
python tool/assemble_release_bundle.py \
  --android-manifest /path/to/android/ASTRO_LOGIC_Android_vX.Y.Z+N_RELEASE_MANIFEST.json \
  --windows-manifest /path/to/windows/ASTRO_LOGIC_Windows_vX.Y.Z+N_RELEASE_MANIFEST.json \
  --output-dir ~/ASTRO_LOGIC_FINAL_RELEASE
```

Android/Windows version, tag, commit, Flutter version বা lock SHA আলাদা হলে final
bundle তৈরি হবে না।

## 7. Distribution-এর আগে

GitHub CI pass-এর পরও Android real-device এবং Windows real-machine acceptance
check করতে হবে। `RELEASE_GATE.md`-এর acceptance checklist সম্পূর্ণ না হওয়া পর্যন্ত
commercial distribution করবেন না।
