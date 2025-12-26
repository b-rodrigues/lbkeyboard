# Composable Rules System

The lbkeyboard package includes a **composable rules system** that lets
you customize the keyboard optimization with constraints and
preferences. Rules can be combined freely to express complex
requirements.

## Setup

``` r
library(lbkeyboard)
data("french")
```

## Types of Rules

There are two types of rules:

| Type                 | Description                               |
|----------------------|-------------------------------------------|
| **Hard constraints** | Keys cannot move from their position      |
| **Soft preferences** | Penalty added when preference is violated |

### Hard Constraints

#### `fix_keys()` - Lock Keys in Place

Use
[`fix_keys()`](https://b-rodrigues.github.io/lbkeyboard/reference/fix_keys.md)
to prevent certain keys from moving during optimization. This is useful
for preserving keyboard shortcuts:

``` r
# Keep Ctrl+Z, Ctrl+X, Ctrl+C, Ctrl+V shortcuts
rule <- fix_keys(c("z", "x", "c", "v"))
print(rule)
#> Layout Rule: fix 
#>   Fixed keys: z, x, c, v
```

Keys are matched case-insensitively:

``` r
# These are equivalent
fix_keys(c("A", "B"))
#> Layout Rule: fix 
#>   Fixed keys: a, b
fix_keys(c("a", "b"))
#> Layout Rule: fix 
#>   Fixed keys: a, b
```

### Soft Preferences

Soft preferences add a penalty to the effort score when not satisfied.
The **weight** parameter controls how strongly the preference is
enforced.

#### `prefer_hand()` - Hand Placement Preference

Specify which keys should go on which hand:

``` r
# Put vowels on the left hand
rule <- prefer_hand(
  keys = c("a", "e", "i", "o", "u"),
  hand = "left",
  weight = 2.0
)
print(rule)
#> Layout Rule: prefer_hand 
#>   Keys: a, e, i, o, u ->  left hand (weight: 2 )
```

This adds a penalty of 2.0 for each vowel that ends up on the right
hand.

#### `prefer_row()` - Row Placement Preference

Specify which row keys should be placed on:

- Row 1 = Top row (QWERTY row)
- Row 2 = Home row (ASDF row)
- Row 3 = Bottom row (ZXCV row)

``` r
# Put the most common English letters on home row
common_letters <- c("e", "t", "a", "o", "i", "n", "s", "r")
rule <- prefer_row(common_letters, row = 2, weight = 1.5)
print(rule)
#> Layout Rule: prefer_row 
#>   Keys: e, t, a, o, i, n, s, r -> row 2 (weight: 1.5 )
```

The penalty is proportional to the distance from the target row.

#### `balance_hands()` - Hand Usage Balance

Aim for balanced typing load between hands:

``` r
# Target 50% left, 50% right
rule <- balance_hands(target = 0.5, weight = 1.0)
print(rule)
#> Layout Rule: balance_hands 
#>   Target: 50 % left hand (weight: 1 )

# Or slight preference for right hand (40% left, 60% right)
rule_right <- balance_hands(target = 0.4, weight = 1.0)
```

The penalty increases quadratically as the actual balance deviates from
target.

#### `keep_like()` - Match Reference Layout

Keep specified keys in similar positions to a reference layout:

``` r
# Keep bottom row like QWERTY
rule <- keep_like(
  reference = "qwerty",
  keys = c("z", "x", "c", "v", "b", "n", "m"),
  weight = 3.0
)
print(rule)
#> Layout Rule: keep_like 
#>   Match reference for: z, x, c, v, b, n, m (weight: 3 )
```

## Combining Rules

The real power comes from combining multiple rules. Pass a list of rules
to
[`optimize_layout()`](https://b-rodrigues.github.io/lbkeyboard/reference/optimize_layout.md):

``` r
result <- optimize_layout(
  text_samples = french,
  rules = list(
    # Hard: keep shortcut keys fixed
    fix_keys(c("z", "x", "c", "v")),
    
    # Soft: vowels on left hand
    prefer_hand(c("a", "e", "i", "o", "u"), "left", weight = 2.0),
    
    # Soft: common letters on home row
    prefer_row(c("e", "t", "a", "o", "n", "i", "s", "r"), 2, weight = 1.0),
    
    # Soft: aim for balanced hands
    balance_hands(0.5, weight = 0.5)
  ),
  generations = 50,
  verbose = FALSE
)
#> Warning: input string 'é' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning: input string 'è' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning: input string 'ä' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning: input string 'ü' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning: input string 'é' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning: input string 'è' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning: input string 'ä' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning: input string 'ü' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Au commencement, Dieu créa les cieux et la terre.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'La terre était informe et vide: il y avait des ténèbres à la
#> surface de l'abîme, et l'esprit de Dieu se mouvait au-dessus des eaux.' cannot
#> be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu dit: Que la lumière soit! Et la lumière fut.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu vit que la lumière était bonne; et Dieu sépara la lumière
#> d'avec les ténèbres.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but
#> is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu appela la lumière jour, et il appela les ténèbres nuit.
#> Ainsi, il y eut un soir, et il y eut un matin: ce fut le premier jour.' cannot
#> be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu dit: Qu'il y ait une étendue entre les eaux, et qu'elle
#> sépare les eaux d'avec les eaux.' cannot be translated from 'ANSI_X3.4-1968' to
#> UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Et Dieu fit l'étendue, et il sépara les eaux qui sont
#> au-dessous de l'étendue d'avec les eaux qui sont au-dessus de l'étendue. Et
#> cela fut ainsi.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is
#> valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu appela l'étendue ciel. Ainsi, il y eut un soir, et il y
#> eut un matin: ce fut le second jour.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu appela le sec terre, et il appela l'amas des eaux mers.
#> Dieu vit que cela était bon.' cannot be translated from 'ANSI_X3.4-1968' to
#> UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Puis Dieu dit: Que la terre produise de la verdure, de l'herbe
#> portant de la semence, des arbres fruitiers donnant du fruit selon leur espèce
#> et ayant en eux leur semence sur la terre. Et cela fut ainsi.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'La terre produisit de la verdure, de l'herbe portant de la
#> semence selon son espèce, et des arbres donnant du fruit et ayant en eux leur
#> semence selon leur espèce. Dieu vit que cela était bon.' cannot be translated
#> from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Ainsi, il y eut un soir, et il y eut un matin: ce fut le
#> troisième jour.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is
#> valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu dit: Qu'il y ait des luminaires dans l'étendue du ciel,
#> pour séparer le jour d'avec la nuit; que ce soient des signes pour marquer les
#> époques, les jours et les années;' cannot be translated from 'ANSI_X3.4-1968'
#> to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'et qu'ils servent de luminaires dans l'étendue du ciel, pour
#> éclairer la terre. Et cela fut ainsi.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu fit les deux grands luminaires, le plus grand luminaire
#> pour présider au jour, et le plus petit luminaire pour présider à la nuit; il
#> fit aussi les étoiles.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu les plaça dans l'étendue du ciel, pour éclairer la terre,'
#> cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'pour présider au jour et à la nuit, et pour séparer la lumière
#> d'avec les ténèbres. Dieu vit que cela était bon.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Ainsi, il y eut un soir, et il y eut un matin: ce fut le
#> quatrième jour.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is
#> valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu dit: Que les eaux produisent en abondance des animaux
#> vivants, et que des oiseaux volent sur la terre vers l'étendue du ciel.' cannot
#> be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu créa les grands poissons et tous les animaux vivants qui
#> se meuvent, et que les eaux produisirent en abondance selon leur espèce; il
#> créa aussi tout oiseau ailé selon son espèce. Dieu vit que cela était bon.'
#> cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu les bénit, en disant: Soyez féconds, multipliez, et
#> remplissez les eaux des mers; et que les oiseaux multiplient sur la terre.'
#> cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Ainsi, il y eut un soir, et il y eut un matin: ce fut le
#> cinquième jour.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is
#> valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu dit: Que la terre produise des animaux vivants selon leur
#> espèce, du bétail, des reptiles et des animaux terrestres, selon leur espèce.
#> Et cela fut ainsi.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is
#> valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu fit les animaux de la terre selon leur espèce, le bétail
#> selon son espèce, et tous les reptiles de la terre selon leur espèce. Dieu vit
#> que cela était bon.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but
#> is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Puis Dieu dit: Faisons l'homme à notre image, selon notre
#> ressemblance, et qu'il domine sur les poissons de la mer, sur les oiseaux du
#> ciel, sur le bétail, sur toute la terre, et sur tous les reptiles qui rampent
#> sur la terre.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is
#> valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu créa l'homme à son image, il le créa à l'image de Dieu, il
#> créa l'homme et la femme.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu les bénit, et Dieu leur dit: Soyez féconds, multipliez,
#> remplissez la terre, et l'assujettissez; et dominez sur les poissons de la mer,
#> sur les oiseaux du ciel, et sur tout animal qui se meut sur la terre.' cannot
#> be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Et Dieu dit: Voici, je vous donne toute herbe portant de la
#> semence et qui est à la surface de toute la terre, et tout arbre ayant en lui
#> du fruit d'arbre et portant de la semence: ce sera votre nourriture.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Et à tout animal de la terre, à tout oiseau du ciel, et à tout
#> ce qui se meut sur la terre, ayant en soi un souffle de vie, je donne toute
#> herbe verte pour nourriture. Et cela fut ainsi.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Dieu vit tout ce qu'il avait fait et voici, cela était très
#> bon. Ainsi, il y eut un soir, et il y eut un matin: ce fut le sixième jour.'
#> cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Joe Paterno, né le 21 décembre 1926 à Brooklyn et mort le 22
#> janvier 2012 à State College, est un joueur et entraîneur américain de football
#> américain universitaire. Figure historique et emblématique des Nittany Lions de
#> Penn State entre 1966 et 2011, il est l'entraîneur le plus victorieux de
#> l'histoire du football américain universitaire avec 409 succès en Division I.
#> Son image est toutefois ternie en fin de carrière à cause de soupçons de
#> négligence dans une affaire d'agressions sexuelles sur mineurs.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Lors de ses brillantes études de droit à l'université Brown,
#> Joe Paterno joue au football américain et est entraîné par Rip Engle. Ce
#> dernier, embauché par l'université de Penn State, le recrute comme entraîneur
#> assistant en 1950. Pendant quinze saisons, l'assistant fait ses preuves avant
#> de devenir entraîneur principal des Nittany Lions en 1965. Surnommé JoePa, il
#> connaît rapidement le succès. Invaincu en 1968 et 1969, il est désiré par
#> plusieurs franchises de la National Football League (NFL), mais refuse pour
#> conserver son rôle d'éducateur. Entraîneur de l'équipe universitaire championne
#> en 1982 et 1986, vainqueur des quatre principaux Bowls universitaires, il
#> intègre le College Football Hall of Fame en 2007 alors qu'il est encore en
#> activité, un accomplissement rare.' cannot be translated from 'ANSI_X3.4-1968'
#> to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Reconnu pour ses succès sportifs, académiques et son
#> exemplarité, JoePa est adulé comme une icône populaire dans la région de State
#> College. Onze jours après avoir célébré sa 409e victoire avec les Lions, il est
#> démis de ses fonctions à la suite du scandale des agressions sexuelles de
#> l'Université d'État de Pennsylvanie. Accusé d'avoir couvert les abus sexuels de
#> Jerry Sandusky, son image est ternie par cette affaire au retentissement
#> international. Il meurt deux mois plus tard des suites d'un cancer du poumon.'
#> cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Chacun peut publier immédiatement du contenu en ligne, à
#> condition de respecter les règles essentielles établies par la Fondation
#> Wikimedia et par la communauté ; par exemple, la vérifiabilité du contenu,
#> l'admissibilité des articles et garder une attitude cordiale.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'De nombreuses pages d’aide sont à votre disposition, notamment
#> pour créer un article, modifier un article ou insérer une image. N’hésitez pas
#> à poser une question pour être aidé dans vos premiers pas, notamment dans un
#> des projets thématiques ou dans divers espaces de discussion.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Les pages de discussion servent à centraliser les réflexions et
#> les remarques permettant d’améliorer les articles.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'En 1894, l’explorateur Gustav Adolf von Götzen suivait les
#> traces d’un missionnaire en provenance de la cote orientale d’Afrique. Pendant
#> qu’il se rendait au Rwanda, il découvre un petit village des pécheurs appelé
#> Ngoma qui traduit signifie tam tam, par déformation il écrivit Goma. Ngoma
#> devint un poste belge en face de celui de Rubavu (au Rwanda) habité par les
#> Allemands. Au début, la cohabitation entre ces deux postes n’était pas facile.
#> À un certain moment, les chefs coutumiers du Rwanda, en complicité avec les
#> Allemands attaquent les Belges de Goma. Ces derniers se réfugient à Bukavu et
#> laissent les envahisseurs occuper la ville. Après des négociations, les
#> Allemands replient vers le Rwanda et les Belges reprennent leur position
#> initiale comme poste colonial. L’afflux des colonisateurs dans ce village joue
#> un rôle important dans son évolution pour devenir une grande agglomération. Les
#> colonisateurs venaient d’installer le chef lieu du [... truncated]
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'En ce moment, Goma reste un poste de transaction lacustre avec
#> Bukavu qui était une ville minière. Plus tard, Rutshuru, Masisi, Kalehe,
#> Gisenyi, etc. déverseront leurs populations dans Goma, à la rechercher de
#> l’emploi au près des colonisateurs. C’est en cette période que vu le jour le
#> quartier Birere (un bidonville de Goma) autour des entrepôts, bureaux et
#> habitations des colons. Le nom Birere (littéralement feuilles de bananier)
#> vient du fait qu’à l’époque, les gens y construisaient en feuilles des
#> bananiers.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid
#> UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'La ville est la base arrière de l'opération Turquoise organisée
#> en 1994 à la fin du génocide rwandais.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'La ville et ses environs abriteront dans des camps autour de
#> 650 000 réfugiés hutus de 1994 jusqu'à la chute du Zaïre, dont certains
#> supposés anciens génocidaires. Selon des ONG, l'AFDL procède à des massacres
#> dans les camps entre 1996 et 19971.' cannot be translated from 'ANSI_X3.4-1968'
#> to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'De 1998 à 2002/2003, la ville, sous contrôle du Rassemblement
#> congolais pour la démocratie (RCD) pro-rwandais échappe au contrôle du
#> gouvernement congolais.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'De nombreux viols, massacres et crimes de guerre y ont été
#> perpétrés entre 1996 et 2006 par les troupes des généraux rebelles du RCD,
#> essentiellement sous les généraux Nkundabatware et Mutebusi.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'En 2002, le Nyiragongo entra en éruption, et une coulée de lave
#> atteignit le centre de la ville. La lave n'a pas atteint le lac Kivu fort
#> heureusement, en effet ce lac est un lac méromictique et un changement brutal
#> de chaleur aurait des conséquences graves : Éruption limnique.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = french, rules = list(fix_keys(c("z",
#> : input string 'Débordant de populations fuyant les violences, Goma compte en
#> 2012 plus de 400 000 habitants. Ceux qui ne peuvent pas trouver d'abri
#> remplissent les camps de réfugiés, où l'ONU et les ONG se débattent pour leur
#> fournir nourriture, eau et combustible.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
```

``` r
print_layout(result$layout)
#> ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
#> │ U │ J │ Y │ B │ F │ D │ S │ P │ K │ G │
#> ├───┼───┼───┼───┼───┼───┼───┼───┼───┘
#> │ A │ O │ H │ I │ E │ R │ N │ T │ M │
#> ├───┼───┼───┼───┼───┼───┼───┘
#> │ Z │ X │ C │ V │ L │ W │ Q │
#> └───┴───┴───┴───┴───┴───┴───┘
cat("\nImprovement:", round(result$improvement, 2), "%\n")
#> 
#> Improvement: 27.95 %
```

## Choosing Weights

The **weight** parameter determines how strongly each preference
influences the optimization. Here are some guidelines:

| Weight    | Effect                                |
|-----------|---------------------------------------|
| 0.5 - 1.0 | Mild preference, may be overridden    |
| 1.0 - 2.0 | Moderate preference                   |
| 2.0 - 5.0 | Strong preference                     |
| 5.0+      | Very strong, almost like a constraint |

**Tips:**

- Start with weight = 1.0 and adjust based on results
- Higher weights can slow convergence
- Balance between typing efficiency and your preferences

## Examples

### Ergonomic Vowels Layout

Put vowels on strong fingers of the left hand:

``` r
result <- optimize_layout(
  text_samples = french,
  rules = list(
    # Vowels on left hand
    prefer_hand(c("a", "e", "i", "o", "u"), "left", weight = 3.0),
    
    # Common consonants on right hand
    prefer_hand(c("t", "n", "s", "r", "l"), "right", weight = 2.0),
    
    # Most frequent on home row
    prefer_row(c("e", "t", "a", "n", "i", "s"), 2, weight = 1.5)
  ),
  generations = 50,
  verbose = FALSE
)
```

``` r
print_layout(result$layout)
#> ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
#> │ Z │ H │ K │ O │ V │ L │ C │ X │ G │ D │
#> ├───┼───┼───┼───┼───┼───┼───┼───┼───┘
#> │ U │ I │ E │ A │ N │ R │ T │ S │ B │
#> ├───┼───┼───┼───┼───┼───┼───┘
#> │ Y │ F │ W │ P │ J │ Q │ M │
#> └───┴───┴───┴───┴───┴───┴───┘
```

### Preserving Familiar Keys

Keep commonly-used keys in familiar positions:

``` r
result <- optimize_layout(
  text_samples = french,
  rules = list(
    # Hard: fix entire bottom row
    fix_keys(c("z", "x", "c", "v", "b", "n", "m")),
    
    # Soft: keep remaining keys roughly like QWERTY
    keep_like("qwerty", weight = 0.5)
  ),
  generations = 50,
  verbose = FALSE
)
```

``` r
print_layout(result$layout)
#> ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
#> │ W │ H │ G │ K │ O │ L │ P │ F │ J │ Y │
#> ├───┼───┼───┼───┼───┼───┼───┼───┼───┘
#> │ R │ T │ Q │ A │ E │ D │ U │ S │ I │
#> ├───┼───┼───┼───┼───┼───┼───┘
#> │ Z │ X │ C │ V │ B │ N │ M │
#> └───┴───┴───┴───┴───┴───┴───┘
cat("Fixed:", result$n_fixed, "keys\n")
#> Fixed: 7 keys
```

### Balanced Multilingual Layout

Optimize for multiple languages with balanced hands:

``` r
data("german")
data("english")

result <- optimize_layout(
  text_samples = c(french, german, english),
  rules = list(
    # Keep shortcuts
    fix_keys(c("z", "x", "c", "v")),
    
    # Strict hand balance for multilingual comfort
    balance_hands(0.5, weight = 2.0)
  ),
  generations = 50,
  verbose = FALSE
)
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und die Erde war wüst und leer, und es war
#> finster auf der Tiefe; und der Geist Gottes schwebte auf dem Wasser.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott sah, daß das Licht gut war. Da
#> schied Gott das Licht von der Finsternis' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Da machte Gott die Feste und schied das
#> Wasser unter der Feste von dem Wasser über der Feste. Und es geschah also.'
#> cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott sprach: Es sammle sich das Wasser
#> unter dem Himmel an besondere Örter, daß man das Trockene sehe. Und es geschah
#> also.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott nannte das Trockene Erde, und die
#> Sammlung der Wasser nannte er Meer. Und Gott sah, daß es gut war.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott sprach: Es lasse die Erde
#> aufgehen Gras und Kraut, das sich besame, und fruchtbare Bäume, da ein
#> jeglicher nach seiner Art Frucht trage und habe seinen eigenen Samen bei sich
#> selbst auf Erden. Und es geschah also.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und die Erde ließ aufgehen Gras und Kraut,
#> das sich besamte, ein jegliches nach seiner Art, und Bäume, die da Frucht
#> trugen und ihren eigenen Samen bei sich selbst hatten, ein jeglicher nach
#> seiner Art. Und Gott sah, daß es gut war.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'und seien Lichter an der Feste des
#> Himmels, daß sie scheinen auf Erden. Und es geschah also.' cannot be translated
#> from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott machte zwei große Lichter: ein
#> großes Licht, das den Tag regiere, und ein kleines Licht, das die Nacht
#> regiere, dazu auch Sterne.' cannot be translated from 'ANSI_X3.4-1968' to
#> UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott setzte sie an die Feste des
#> Himmels, daß sie schienen auf die Erde' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'und den Tag und die Nacht regierten und
#> schieden Licht und Finsternis. Und Gott sah, daß es gut war.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott sprach: Es errege sich das Wasser
#> mit webenden und lebendigen Tieren, und Gevögel fliege auf Erden unter der
#> Feste des Himmels.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is
#> valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott schuf große Walfische und
#> allerlei Getier, daß da lebt und webt, davon das Wasser sich erregte, ein
#> jegliches nach seiner Art, und allerlei gefiedertes Gevögel, ein jegliches nach
#> seiner Art. Und Gott sah, daß es gut war.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott segnete sie und sprach: Seid
#> fruchtbar und mehrt euch und erfüllt das Wasser im Meer; und das Gefieder mehre
#> sich auf Erden.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is
#> valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Da ward aus Abend und Morgen der fünfte
#> Tag.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott sprach: Die Erde bringe hervor
#> lebendige Tiere, ein jegliches nach seiner Art: Vieh, Gewürm und Tiere auf
#> Erden, ein jegliches nach seiner Art. Und es geschah also.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott machte die Tiere auf Erden, ein
#> jegliches nach seiner Art, und das Vieh nach seiner Art, und allerlei Gewürm
#> auf Erden nach seiner Art. Und Gott sah, daß es gut war.' cannot be translated
#> from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott sprach: Laßt uns Menschen machen,
#> ein Bild, das uns gleich sei, die da herrschen über die Fische im Meer und über
#> die Vögel unter dem Himmel und über das Vieh und über die ganze Erde und über
#> alles Gewürm, das auf Erden kriecht.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott segnete sie und sprach zu ihnen:
#> Seid fruchtbar und mehrt euch und füllt die Erde und macht sie euch untertan
#> und herrscht über die Fische im Meer und über die Vögel unter dem Himmel und
#> über alles Getier, das auf Erden kriecht.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Und Gott sprach: Seht da, ich habe euch
#> gegeben allerlei Kraut, das sich besamt, auf der ganzen Erde und allerlei
#> fruchtbare Bäume, die sich besamen, zu eurer Speise,' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'und allem Getier auf Erden und allen
#> Vögeln unter dem Himmel und allem Gewürm, das da lebt auf Erden, daß sie
#> allerlei grünes Kraut essen. Und es geschah also.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Während des Bürgerkrieges und Völkermords
#> im nahe angrenzenden Ruanda 1994 war Goma eines der Hauptziele für Flüchtlinge.
#> Unter diesen waren nebst Zivilisten auch Mittäter des Genozids. Nachdem über
#> eine Million Flüchtlinge die Stadt erreicht hatten, brach in den Lagern eine
#> Cholera-Epidemie aus, die mehrere Tausend Opfer forderte. In den Jahren 1997
#> und 1998, als der Bürgerkrieg im Kongo nach dem Sturz von Präsident Mobutu Sese
#> Seko eskalierte, eroberten ruandische Regierungstruppen Goma. Im Zuge der
#> Verfolgung von Hutu, die in der Stadt Zuflucht gesucht hatten, töteten sie auch
#> Hunderte Unbeteiligte.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8,
#> but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Im Jahre 2002 wurde die Stadt von einem
#> Lavastrom aus dem etwa 14 km entfernten Nyiragongo im Norden zu großen Teilen
#> zerstört. Viele Gebäude gerade im Stadtzentrum sowie der Flughafen Goma waren
#> betroffen. Von den 3.000 Metern der Start- und Landebahn sind bis heute noch
#> fast 1.000 Meter unter einer Lavaschicht begraben, so dass der internationale
#> Verkehr ihn meidet. Rund 250.000 Einwohner der Stadt mussten flüchten. Es gab
#> 147 Todesopfer, viele Flüchtlinge blieben obdachlos oder haben sich am Rande
#> der Lavafelder Notunterkünfte gebaut. Seit April 2009 wird unter Führung der
#> Welthungerhilfe das Rollfeld des Flughafens von der Lava befreit. Die
#> Bedrohung, dass sich bei einer erneuten Eruption Lavamassen aus dem innerhalb
#> des Vulkankraters befindlichen Lavasee erneut ins Tal und auf die Stadt
#> ergießen, besteht nach wie vor.[3]' cannot be translated from 'ANSI_X3.4-1968'
#> to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Am 15. April 2008 raste nach dem Start vom
#> Flughafen Goma eine Douglas DC-9 mit 79 Passagieren und 6 Besatzungsmitgliedern
#> über das südliche Startbahnende hinaus in das Wohn- und Marktgebiet Birere.
#> Etwa 40 Personen aus dem angrenzenden Siedlungsgebiet kamen ums Leben,
#> mindestens 53 Passagiere und die 6 Besatzungsmitglieder überlebten jedoch. Das
#> Feuer aus dem brennenden Wrack konnte sich aufgrund des starken Regens nicht
#> ausbreiten, Anwohner konnten das Feuer zusätzlich eindämmen.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Am 21. November 2012 wurden große Teile
#> der Stadt von der gegen die Zentralregierung unter Präsident Joseph Kabila
#> kämpfenden Rebellenbewegung M23 eingenommen. Dort stationierte
#> UNO-Friedens-Truppen griffen im Gegensatz zu früheren Aktivitäten nicht mehr
#> ein.[5] Am 1. Dezember begannen sie nach Überschreitung eines Ultimatums der
#> Internationalen Konferenz der Großen Seen Afrikas und zwei Resolutionen des
#> UN-Sicherheitsrats, sich aus der Stadt zurückzuziehen.' cannot be translated
#> from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Im Jahre 2019 wurden mehrere Einzelfälle
#> von Ebola in der Stadt registriert, nachdem die Ebola Epidemie bereits zuvor im
#> Ostkongo ausgebrochen war.[6]' cannot be translated from 'ANSI_X3.4-1968' to
#> UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Seit 1959 ist Goma Sitz des
#> römisch-katholischen Bistums Goma.' cannot be translated from 'ANSI_X3.4-1968'
#> to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Die Transporteure werden Frachtführer (in
#> Österreich Frächter) genannt. Sie organisieren nicht den Transport, sondern
#> führen diesen aus, meistens im Auftrag eines Spediteurs. Die Höhe der Fracht
#> wird im Frachtvertrag vereinbart und in der Regel im Frachtbrief festgehalten.
#> Seit mit der Transportrechtsreform 1998 in Deutschland die Erstellung eines
#> Frachtbriefes für nationale Transporte nicht mehr zwingend erforderlich ist,
#> sondern auch Lieferscheine, Ladelisten oder vergleichbare Papiere als
#> Warenbegleitdokument verwendet werden können, wird zunehmend kein Frachtbrief
#> mehr ausgestellt. Beim Frachtbrief gibt es drei Originalausfertigungen. Eine
#> Ausfertigung verbleibt beim Absender, nachdem ihm darauf der Frachtführer die
#> Übernahme des Frachtguts bestätigt hat. Die zweite verbleibt nach Ablieferung
#> des Frachtguts als Ablieferbestätigung beim Frachtführer und die dritte erhält
#> der Empfänger.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is
#> valid UTF [... truncated]
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Für die Verladung des Frachtguts ist der
#> Absender zuständig. Er ist dabei gem. § 412 HGB für eine beförderungssichere
#> Verladung des Frachtguts verantwortlich, wohingegen der Frachtführer für die
#> verkehrssichere Verladung (z. B. Gewichtsverteilung, Einhaltung der zulässigen
#> Achslasten), als auch für die Ladungssicherung zu sorgen hat.' cannot be
#> translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Bei Kontrollen muss der Frachtbrief den
#> Zoll- und Polizeibehörden, sowie dem Bundesamt für Güterverkehr (BAG)
#> ausgehändigt werden.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but
#> is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Es gibt anmeldepflichtige Frachtgüter, für
#> deren Transport es einer ausdrücklichen behördlichen Genehmigung bedarf.
#> Schwertransporte erfordern eine behördliche Ausnahmegenehmigung und bei
#> Überschreiten bestimmter Abmessungen sind gemäß § 29 Absatz. 3 StVO (Übermäßige
#> Straßennutzung) definitiv Begleitfahrzeuge und/oder eine Begleitung durch die
#> Polizei vorgeschrieben, um Sicherungsmaßnahmen einzuleiten und für einen
#> reibungslosen Ablauf zu sorgen. Fällt das zu befördernde Frachtgut unter die
#> Gefahrgutverordnung, muss das Transportfahrzeug neben der Einhaltung
#> gefahrgutrelevanter Vorschriften auch mit entsprechenden Warntafeln
#> gekennzeichnet sein. Darüber hinaus benötigt dann der Fahrzeugführer und ein
#> eventueller Beifahrer auch eine ADR-Bescheinigung.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Die Aufteilung der Frachtkosten zwischen
#> Absender und Empfänger wird über die im Kaufvertrag festgehaltenen
#> Lieferbedingungen geregelt, im internationalen Warenverkehr durch die
#> Incoterms.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid
#> UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'In 1996, Wales and two partners founded
#> Bomis, a web portal primarily known for featuring adult content. Bomis provided
#> the initial funding for the free peer-reviewed encyclopedia Nupedia
#> (2000–2003). On January 15, 2001, with Larry Sanger and others, Wales launched
#> Wikipedia, a free open-content encyclopedia that enjoyed rapid growth and
#> popularity. As its public profile grew, Wales became its promoter and
#> spokesman. Though he is historically credited as co-founder, he has disputed
#> this, declaring himself the sole founder.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Jesus is also revered in other religions.
#> In Islam, Jesus (often referred to by his Quranic name ʿĪsā) is considered the
#> penultimate prophet of God and the messiah, who will return before the Day of
#> Judgement. Muslims believe Jesus was born of the virgin Mary (another figure
#> revered in Islam), but was neither God nor a son of God; In contrast, Judaism
#> rejects the belief that Jesus was the awaited messiah, arguing that he did not
#> fulfill messianic prophecies, and was neither divine nor resurrected.' cannot
#> be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Formal unification of Germany into the
#> modern nation-state was commenced on 18 August 1866 with the North German
#> Confederation Treaty establishing the Prussia-led North German Confederation
#> later transformed in 1871 into the German Empire. After World War I and the
#> German Revolution of 1918–1919, the Empire was in turn transformed into the
#> semi-presidential Weimar Republic. The Nazi seizure of power in 1933 led to the
#> establishment of a totalitarian dictatorship, World War II, and the Holocaust.
#> After the end of World War II in Europe and a period of Allied occupation, in
#> 1949, Germany as a whole was organized into two separate polities with limited
#> sovereignity: the Federal Republic of Germany, generally known as West Germany,
#> and the German Democratic Republic, East Germany, while Berlin de jure
#> continued its Four Power status. The Federal Republic of Germany was a founding
#> member of the European Economic Community and the European Union, while the
#> German Democratic R [... truncated]
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Over the centuries, the City and Fortress
#> of Luxembourg—of great strategic importance due to its location between the
#> Kingdom of France and the Habsburg territories—was gradually built up to be one
#> of the most reputed fortifications in Europe. ' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'Geometrically, this is seen as the sum of
#> the squared distances, parallel to the axis of the dependent variable, between
#> each data point in the set and the corresponding point on the regression
#> surface—the smaller the differences, the better the model fits the data. The
#> resulting estimator can be expressed by a simple formula, especially in the
#> case of a simple linear regression, in which there is a single regressor on the
#> right side of the regression equation.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning in optimize_layout(text_samples = c(french, german, english), rules =
#> list(fix_keys(c("z", : input string 'The OLS estimator is consistent for the
#> level-one fixed effects when the regressors are exogenous and forms perfect
#> colinearity (rank condition), consistent for the variance estimate of the
#> residuals when regressors have finite fourth moments and—by the Gauss–Markov
#> theorem—optimal in the class of linear unbiased estimators when the errors are
#> homoscedastic and serially uncorrelated. Under these conditions, the method of
#> OLS provides minimum-variance mean-unbiased estimation when the errors have
#> finite variances. Under the additional assumption that the errors are normally
#> distributed with zero mean, OLS is the maximum likelihood estimator that
#> outperforms any non-linear unbiased estimator.' cannot be translated from
#> 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
```

``` r
print_layout(result$layout)
#> ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
#> │ Q │ J │ G │ L │ Y │ K │ D │ U │ B │ P │
#> ├───┼───┼───┼───┼───┼───┼───┼───┼───┘
#> │ M │ T │ N │ R │ E │ S │ A │ I │ O │
#> ├───┼───┼───┼───┼───┼───┼───┘
#> │ Z │ X │ C │ V │ W │ H │ F │
#> └───┴───┴───┴───┴───┴───┴───┘
```

## Comparison: With vs Without Rules

Let’s compare optimization results:

``` r
# Without rules
result_plain <- optimize_layout(
  text_samples = french,
  generations = 50,
  verbose = FALSE
)

# With rules
result_rules <- optimize_layout(
  text_samples = french,
  rules = list(
    fix_keys(c("z", "x", "c", "v")),
    prefer_hand(c("a", "e", "i", "o", "u"), "left", weight = 2.0)
  ),
  generations = 50,
  verbose = FALSE
)
```

``` r
cat("Without rules - Effort:", round(result_plain$effort, 2), "\n")
#> Without rules - Effort: 35285.7
print_layout(result_plain$layout)
#> ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
#> │ F │ Y │ D │ Z │ R │ I │ U │ V │ J │ P │
#> ├───┼───┼───┼───┼───┼───┼───┼───┼───┘
#> │ C │ T │ S │ M │ L │ E │ A │ O │ N │
#> ├───┼───┼───┼───┼───┼───┼───┘
#> │ X │ B │ W │ Q │ K │ H │ G │
#> └───┴───┴───┴───┴───┴───┴───┘

cat("\nWith rules - Effort:", round(result_rules$effort, 2), "\n")
#> 
#> With rules - Effort: 40641.18
print_layout(result_rules$layout)
#> ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
#> │ A │ G │ O │ Q │ R │ D │ L │ W │ K │ F │
#> ├───┼───┼───┼───┼───┼───┼───┼───┼───┘
#> │ U │ E │ I │ J │ S │ N │ P │ T │ M │
#> ├───┼───┼───┼───┼───┼───┼───┘
#> │ Z │ X │ C │ V │ Y │ B │ H │
#> └───┴───┴───┴───┴───┴───┴───┘
```

The layout with rules might have slightly higher effort, but it respects
your preferences and constraints.

## Rule Reference

| Function | Parameters | Description |
|----|----|----|
| `fix_keys(keys)` | keys: character vector | Hard constraint - keys don’t move |
| `prefer_hand(keys, hand, weight)` | hand: “left”/“right” | Soft penalty for wrong hand |
| `prefer_row(keys, row, weight)` | row: 1, 2, or 3 | Soft penalty for wrong row |
| `prefer_finger(keys, fingers, weight)` | fingers: 0-9 | Soft penalty for wrong finger |
| `balance_hands(target, weight)` | target: 0-1 | Soft penalty for hand imbalance |
| `keep_like(ref, keys, weight)` | ref: “qwerty” or vector | Soft penalty for layout mismatch |
