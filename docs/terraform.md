## Providers

| Name | Version |
|------|---------|
| archive | ~> 1.3.0 |
| aws | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| attributes | Additional attributes (e.g., `one', or `two') | `list` | `[]` | no |
| delimiter | Delimiter to be used between `namespace`, `stage`, `name`, and `attributes` | `string` | `"-"` | no |
| limit\_tags | The tag key which must be applied to instances | `map` | <pre>{<br>  "CI": [<br>    "true"<br>  ]<br>}</pre> | no |
| max\_age\_minutes | Instances older than this value will be terminated | `number` | n/a | yes |
| name | Name  (e.g. `app` or `database`) | `string` | n/a | yes |
| namespace | Namespace, your org | `string` | n/a | yes |
| regions | List of regions to check for instances in | `list` | n/a | yes |
| schedule | CloudWatch Events rule schedule using cron or rate expression | `string` | `"rate(1 hour)"` | no |
| stage | Environment (e.g. dev, prod, test) | `string` | n/a | yes |
| tags | Additional tags (e.g. map(`Visibility`,`Public`) | `map` | `{}` | no |

## Outputs

No output.

