# Map of MARC relator codes to human-readable terms.
# https://www.loc.gov/marc/relators/relaterm.html

module CocinaDisplay
  MARC_RELATOR = {
    "abr" => "abridger",
    "acp" => "art copyist",
    "act" => "actor",
    "adi" => "art director",
    "adp" => "adapter",
    "aft" => "author of afterword, colophon, etc.", # discontinued
    "anc" => "announcer",
    "anl" => "analyst",
    "anm" => "animator",
    "ann" => "annotator",
    "ant" => "bibliographic antecedent",
    "ape" => "appellee",
    "apl" => "appellant",
    "app" => "applicant",
    "aqt" => "author in quotations or text abstracts",
    "arc" => "architect",
    "ard" => "artistic director",
    "arr" => "arranger",
    "art" => "artist",
    "asg" => "assignee",
    "asn" => "associated name",
    "ato" => "autographer",
    "att" => "attributed name",
    "auc" => "auctioneer",
    "aud" => "author of dialog",
    "aue" => "audio engineer",
    "aui" => "author of introduction, etc.", # discontinued
    "aup" => "audio producer",
    "aus" => "screenwriter",
    "aut" => "author",
    "bdd" => "binding designer",
    "bjd" => "bookjacket designer",
    "bka" => "book artist",
    "bkd" => "book designer",
    "bkp" => "book producer",
    "blw" => "blurb writer",
    "bnd" => "binder",
    "bpd" => "bookplate designer",
    "brd" => "broadcaster",
    "brl" => "braille embosser",
    "bsl" => "bookseller",
    "cad" => "casting director",
    "cas" => "caster",
    "ccp" => "conceptor",
    "chr" => "choreographer",
    "clb" => "collaborator", # discontinued
    "cli" => "client",
    "cll" => "calligrapher",
    "clr" => "colorist",
    "clt" => "collotyper",
    "cmm" => "commentator",
    "cmp" => "composer",
    "cmt" => "compositor",
    "cnd" => "conductor",
    "cng" => "cinematographer",
    "cns" => "censor",
    "coe" => "contestant-appellee",
    "col" => "collector",
    "com" => "compiler",
    "con" => "conservator",
    "cop" => "camera operator",
    "cor" => "collection registrar",
    "cos" => "contestant",
    "cot" => "contestant-appellant",
    "cou" => "court governed",
    "cov" => "cover designer",
    "cpc" => "copyright claimant",
    "cpe" => "complainant-appellee",
    "cph" => "copyright holder",
    "cpl" => "complainant",
    "cpt" => "complainant-appellant",
    "cre" => "creator",
    "crp" => "correspondent",
    "crr" => "corrector",
    "crt" => "court reporter",
    "csl" => "consultant",
    "csp" => "consultant to a project",
    "cst" => "costume designer",
    "ctb" => "contributor",
    "cte" => "contestee-appellee",
    "ctg" => "cartographer",
    "ctr" => "contractor",
    "cts" => "contestee",
    "ctt" => "contestee-appellant",
    "cur" => "curator",
    "cwt" => "commentator for written text",
    "dbd" => "dubbing director",
    "dbp" => "distribution place",
    "dfd" => "defendant",
    "dfe" => "defendant-appellee",
    "dft" => "defendant-appellant",
    "dgc" => "degree committee member",
    "dgg" => "degree granting institution",
    "dgs" => "degree supervisor",
    "dis" => "dissertant",
    "djo" => "dj",
    "dln" => "delineator",
    "dnc" => "dancer",
    "dnr" => "donor",
    "dpc" => "depicted",
    "dpt" => "depositor",
    "drm" => "draftsman",
    "drt" => "director",
    "dsr" => "designer",
    "dst" => "distributor",
    "dtc" => "data contributor",
    "dte" => "dedicatee",
    "dtm" => "data manager",
    "dto" => "dedicator",
    "dub" => "dubious author",
    "edc" => "editor of compilation",
    "edd" => "editorial director",
    "edm" => "editor of moving image work",
    "edt" => "editor",
    "egr" => "engraver",
    "elg" => "electrician",
    "elt" => "electrotyper",
    "eng" => "engineer",
    "enj" => "enacting jurisdiction",
    "etr" => "etcher",
    "evp" => "event place",
    "exp" => "expert",
    "fac" => "facsimilist",
    "fds" => "film distributor",
    "fld" => "field director",
    "flm" => "film editor",
    "fmd" => "film director",
    "fmk" => "filmmaker",
    "fmo" => "former owner",
    "fmp" => "film producer",
    "fnd" => "funder",
    "fon" => "founder",
    "fpy" => "first party",
    "frg" => "forger",
    "gdv" => "game developer",
    "gis" => "geographic information specialist",
    "grt" => "graphic technician", # discontinued
    "his" => "host institution",
    "hnr" => "honoree",
    "hst" => "host",
    "ill" => "illustrator",
    "ilu" => "illuminator",
    "ink" => "inker",
    "ins" => "inscriber",
    "inv" => "inventor",
    "isb" => "issuing body",
    "itr" => "instrumentalist",
    "ive" => "interviewee",
    "ivr" => "interviewer",
    "jud" => "judge",
    "jug" => "jurisdiction governed",
    "lbr" => "laboratory",
    "lbt" => "librettist",
    "ldr" => "laboratory director",
    "led" => "lead",
    "lee" => "libelee-appellee",
    "lel" => "libelee",
    "len" => "lender",
    "let" => "libelee-appellant",
    "lgd" => "lighting designer",
    "lie" => "libelant-appellee",
    "lil" => "libelant",
    "lit" => "libelant-appellant",
    "lsa" => "landscape architect",
    "lse" => "licensee",
    "lso" => "licensor",
    "ltg" => "lithographer",
    "ltr" => "letterer",
    "lyr" => "lyricist",
    "mcp" => "music copyist",
    "mdc" => "metadata contact",
    "med" => "medium",
    "mfp" => "manufacture place",
    "mfr" => "manufacturer",
    "mka" => "makeup artist",
    "mod" => "moderator",
    "mon" => "monitor",
    "mrb" => "marbler",
    "mrk" => "markup editor",
    "msd" => "musical director",
    "mte" => "metal-engraver",
    "mtk" => "minute taker",
    "mup" => "music programmer",
    "mus" => "musician",
    "mxe" => "mixing engineer",
    "nan" => "news anchor",
    "nrt" => "narrator",
    "onp" => "onscreen participant",
    "opn" => "opponent",
    "org" => "originator",
    "orm" => "organizer",
    "osp" => "onscreen presenter",
    "oth" => "other",
    "own" => "owner",
    "pad" => "place of address",
    "pan" => "panelist",
    "pat" => "patron",
    "pbd" => "publishing director",
    "pbl" => "publisher",
    "pdr" => "project director",
    "pfr" => "proofreader",
    "pht" => "photographer",
    "plt" => "platemaker",
    "pma" => "permitting agency",
    "pmn" => "production manager",
    "pnc" => "penciller",
    "pop" => "printer of plates",
    "ppm" => "papermaker",
    "ppt" => "puppeteer",
    "pra" => "praeses",
    "prc" => "process contact",
    "prd" => "production personnel",
    "pre" => "presenter",
    "prf" => "performer",
    "prg" => "programmer",
    "prm" => "printmaker",
    "prn" => "production company",
    "pro" => "producer",
    "prp" => "production place",
    "prs" => "production designer",
    "prt" => "printer",
    "prv" => "provider",
    "pta" => "patent applicant",
    "pte" => "plaintiff-appellee",
    "ptf" => "plaintiff",
    "pth" => "patent holder",
    "ptt" => "plaintiff-appellant",
    "pup" => "publication place",
    "rap" => "rapporteur",
    "rbr" => "rubricator",
    "rcd" => "recordist",
    "rce" => "recording engineer",
    "rcp" => "addressee",
    "rdd" => "radio director",
    "red" => "redaktor",
    "ren" => "renderer",
    "res" => "researcher",
    "rev" => "reviewer",
    "rpc" => "radio producer",
    "rps" => "repository",
    "rpt" => "reporter",
    "rpy" => "responsible party",
    "rse" => "respondent-appellee",
    "rsg" => "restager",
    "rsp" => "respondent",
    "rsr" => "restorationist",
    "rst" => "respondent-appellant",
    "rth" => "research team head",
    "rtm" => "research team member",
    "rxa" => "remix artist",
    "sad" => "scientific advisor",
    "sce" => "scenarist",
    "scl" => "sculptor",
    "scr" => "scribe",
    "sde" => "sound engineer",
    "sds" => "sound designer",
    "sec" => "secretary",
    "sfx" => "special effects provider",
    "sgd" => "stage director",
    "sgn" => "signer",
    "sht" => "spporting host",
    "sll" => "seller",
    "sng" => "singer",
    "spk" => "speaker",
    "spn" => "sponsor",
    "spy" => "second party",
    "srv" => "surveyor",
    "std" => "set designer",
    "stg" => "setting",
    "stl" => "storyteller",
    "stm" => "stage manager",
    "stn" => "standards body",
    "str" => "stereotyper",
    "swd" => "software developer",
    "tad" => "technical advisor",
    "tau" => "television writer",
    "tcd" => "technical director",
    "tch" => "teacher",
    "ths" => "thesis advisor",
    "tld" => "television director",
    "tlg" => "television guest",
    "tlh" => "television host",
    "tlp" => "television producer",
    "trc" => "transcriber",
    "trl" => "translator",
    "tyd" => "type designer",
    "tyg" => "typographer",
    "uvp" => "university place",
    "vac" => "voice actor",
    "vdg" => "videographer",
    "vfx" => "visual effects provider",
    "voc" => "vocalist", # discontinued
    "wac" => "writer of added commentary",
    "wal" => "writer of added lyrics",
    "wam" => "writer of accompanying material",
    "wat" => "writer of added text",
    "waw" => "writer of afterword",
    "wdc" => "woodcutter",
    "wde" => "wood engraver",
    "wfs" => "writer of film story",
    "wft" => "writer of intertitles",
    "wfw" => "writer of foreword",
    "win" => "writer of introduction",
    "wit" => "witness",
    "wpr" => "writer of preface",
    "wst" => "writer of supplementary textual content",
    "wts" => "writer of television story"
  }
end
