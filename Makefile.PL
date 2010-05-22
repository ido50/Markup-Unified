use inc::Module::Install;

name		'Markup-Unified';
all_from	'lib/Markup/Unified.pm';

# required modules
requires	'Class::Accessor' => '0.34';
requires	'Module::Load::Conditional' => '0.38';
test_requires	'Test::More';

# recommended modules
recommends	'Text::Textile' => '2.12';
recommends	'Text::Markdown' => '1.0.25';
recommends	'HTML::BBCode' => '2.06';
recommends	'HTML::Truncate' => '0.20';

WriteAll;
