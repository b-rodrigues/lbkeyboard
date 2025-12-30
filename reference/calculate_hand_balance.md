# Calculate hand balance for a keyboard layout

Calculates the percentage of keystrokes performed by the left and right
hands based on a keyboard layout and letter frequencies.

## Usage

``` r
calculate_hand_balance(kb, freq_df, threshold = NULL)
```

## Arguments

- kb:

  A keyboard layout data frame (must contain `key` and `number`
  columns).

- freq_df:

  A data frame with `characters` and `frequencies` columns.

- threshold:

  Integer. The column index where the split occurs. Keys with
  `number < threshold` are assigned to the left hand. If NULL (default),
  the threshold is adaptively determined based on the minimum column
  index (5 for 0-based indexing, 6 for 1-based indexing).

## Value

A string formatted as "Left%/Right%".

## Examples

``` r
data("ch_qwertz")
data("english")
freq <- letter_freq(english)
#> Warning: input string 'In 1996, Wales and two partners founded Bomis, a web portal primarily known for featuring adult content. Bomis provided the initial funding for the free peer-reviewed encyclopedia Nupedia (2000–2003). On January 15, 2001, with Larry Sanger and others, Wales launched Wikipedia, a free open-content encyclopedia that enjoyed rapid growth and popularity. As its public profile grew, Wales became its promoter and spokesman. Though he is historically credited as co-founder, he has disputed this, declaring himself the sole founder.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning: input string 'Jesus is also revered in other religions. In Islam, Jesus (often referred to by his Quranic name ʿĪsā) is considered the penultimate prophet of God and the messiah, who will return before the Day of Judgement. Muslims believe Jesus was born of the virgin Mary (another figure revered in Islam), but was neither God nor a son of God;  In contrast, Judaism rejects the belief that Jesus was the awaited messiah, arguing that he did not fulfill messianic prophecies, and was neither divine nor resurrected.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning: input string 'Formal unification of Germany into the modern nation-state was commenced on 18 August 1866 with the North German Confederation Treaty establishing the Prussia-led North German Confederation later transformed in 1871 into the German Empire. After World War I and the German Revolution of 1918–1919, the Empire was in turn transformed into the semi-presidential Weimar Republic. The Nazi seizure of power in 1933 led to the establishment of a totalitarian dictatorship, World War II, and the Holocaust. After the end of World War II in Europe and a period of Allied occupation, in 1949, Germany as a whole was organized into two separate polities with limited sovereignity: the Federal Republic of Germany, generally known as West Germany, and the German Democratic Republic, East Germany, while Berlin de jure continued its Four Power status. The Federal Republic of Germany was a founding member of the European Economic Community and the European Union, while the German Democratic R [... truncated]
#> Warning: input string 'Over the centuries, the City and Fortress of Luxembourg—of great strategic importance due to its location between the Kingdom of France and the Habsburg territories—was gradually built up to be one of the most reputed fortifications in Europe. ' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning: input string 'Geometrically, this is seen as the sum of the squared distances, parallel to the axis of the dependent variable, between each data point in the set and the corresponding point on the regression surface—the smaller the differences, the better the model fits the data. The resulting estimator can be expressed by a simple formula, especially in the case of a simple linear regression, in which there is a single regressor on the right side of the regression equation.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
#> Warning: input string 'The OLS estimator is consistent for the level-one fixed effects when the regressors are exogenous and forms perfect colinearity (rank condition), consistent for the variance estimate of the residuals when regressors have finite fourth moments   and—by the Gauss–Markov theorem—optimal in the class of linear unbiased estimators when the errors are homoscedastic and serially uncorrelated. Under these conditions, the method of OLS provides minimum-variance mean-unbiased estimation when the errors have finite variances. Under the additional assumption that the errors are normally distributed with zero mean, OLS is the maximum likelihood estimator that outperforms any non-linear unbiased estimator.' cannot be translated from 'ANSI_X3.4-1968' to UTF-8, but is valid UTF-8
calculate_hand_balance(ch_qwertz, freq)
#> Error in calculate_hand_balance(ch_qwertz, freq): could not find function "calculate_hand_balance"
```
