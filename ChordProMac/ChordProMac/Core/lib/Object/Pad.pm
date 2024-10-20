#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2024 -- leonerd@leonerd.org.uk

package Object::Pad 0.814;

use v5.18;
use warnings;

use Carp;

sub dl_load_flags { 0x01 }

require DynaLoader;
__PACKAGE__->DynaLoader::bootstrap( our $VERSION );

our $XSAPI_VERSION = "0.48";

# So that feature->import will work in `class`
require feature;
if( $] >= 5.020 ) {
   require experimental;
   require indirect if $] < 5.031009;
}

require mro;

require Object::Pad::MOP::Class;

=encoding UTF-8

=for highlighter language=perl

=head1 NAME

C<Object::Pad> - a simple syntax for lexical field-based objects

=head1 SYNOPSIS

On perl version 5.26 onwards:

   use v5.26;
   use Object::Pad;

   class Point {
      field $x :param = 0;
      field $y :param = 0;

      method move ($dX, $dY) {
         $x += $dX;
         $y += $dY;
      }

      method describe () {
         print "A point at ($x, $y)\n";
      }
   }

   Point->new(x => 5, y => 10)->describe;

Or, for older perls that lack signatures:

   use Object::Pad;

   class Point {
      field $x :param = 0;
      field $y :param = 0;

      method move {
         my ($dX, $dY) = @_;
         $x += $dX;
         $y += $dY;
      }

      method describe {
         print "A point at ($x, $y)\n";
      }
   }

   Point->new(x => 5, y => 10)->describe;

=head1 DESCRIPTION

This module provides a simple syntax for creating object classes, which uses
private variables that look like lexicals as object member fields.

While most of this module has evolved into a stable state in practice, parts
remain B<experimental> because the design is still evolving, and many features
and ideas have yet to implemented. I don't yet guarantee I won't have to
change existing details in order to continue its development. Feel free to try
it out in experimental or newly-developed code, but don't complain if a later
version is incompatible with your current code and you'll have to change it.

That all said, please do get in contact if you find the module overall useful.
The more feedback you provide in terms of what features you are using, what
you find works, and what doesn't, will help the ongoing development and
hopefully eventual stability of the design. See the L</FEEDBACK> section.

=head2 Experimental Features

I<Since version 0.63.>

Some of the features of this module are currently marked as experimental. They
will provoke warnings in the C<experimental> category, unless silenced.

You can silence this with C<no warnings 'experimental'> but then that will
silence every experimental warning, which may hide others unintentionally. For
a more fine-grained approach you can instead use the import line for this
module to only silence the module's warnings selectively:

   use Object::Pad ':experimental(mop)';

   use Object::Pad ':experimental(custom_field_attr)';

   use Object::Pad ':experimental(composed_adjust)';

   use Object::Pad ':experimental(inherit_field)';

   use Object::Pad ':experimental(:all)';  # all of the above

I<Since version 0.64.>

Multiple experimental features can be enabled at once by giving multiple names
in the parens, separated by spaces:

   use Object::Pad ':experimental(mop custom_field_attr)';

I<Since version 0.810> attempting to request all of the experiments at once
by using an empty C<:experimental()> is currently accepted, but yields a
warning. This may be removed in future.

=head2 Automatic Construction

Classes are automatically provided with a constructor method, called C<new>,
which helps create the object instances. This may respond to passed arguments,
automatically assigning values of fields, and invoking other blocks of code
provided by the class. It proceeds in the following stages:

=head3 The BUILDARGS phase

If the class provides a C<BUILDARGS> class method, that is used to mangle the
list of arguments before the C<BUILD> blocks are called. Note this must be a
class method not an instance method (and so implemented using C<sub>). It
should perform any C<SUPER> chaining as may be required.

   @args = $class->BUILDARGS( @_ )

=head3 Field assignment

If any field in the class has the C<:param> attribute, then the constructor
will expect to receive its argmuents in an even-sized list of name/value
pairs. This applies even to fields inherited from the parent class or applied
roles. It is therefore a good idea to shape the parameters to the constructor
in this way in roles, and in classes if you intend your class to be extended.

The constructor will also check for required parameters (these are all the
parameters for fields that do not have default initialisation expressions). If
any of these are missing an exception is thrown.

=head3 The BUILD phase

As part of the construction process, the C<BUILD> block of every component
class will be invoked, passing in the list of arguments the constructor was
invoked with. Each class should perform its required setup behaviour, but does
not need to chain to the C<SUPER> class first; this is handled automatically.

=head3 The ADJUST phase

Next, the C<ADJUST> block of every component class is invoked. This happens
after the fields are assigned their initial values and the C<BUILD> blocks
have been run.

=head3 The strict-checking phase

Finally, before the object is returned, if the L</:strict(params)> class
attribute is present, then the constructor will throw an exception if there
are any remaining named arguments left over after assigning them to fields as
per C<:param> declarations, and running any C<ADJUST> blocks.

=head1 KEYWORDS

=head2 class

   class Name :ATTRS... {
      ...
   }

   class Name :ATTRS...;

Behaves similarly to the C<package> keyword, but provides a package that
defines a new class. Such a class provides an automatic constructor method
called C<new>.

As with C<package>, an optional block may be provided. If so, the contents of
that block define the new class and the preceding package continues
afterwards. If not, it sets the class as the package context of following
keywords and definitions.

As with C<package>, an optional version declaration may be given. If so, this
sets the value of the package's C<$VERSION> variable.

   class Name VERSION { ... }

   class Name VERSION;

An optional list of attributes may be supplied in similar syntax as for subs
or lexical variables. (These are annotations about the class itself; the
concept should not be confused with per-object-instance data, which here is
called "fields").

Whitespace is permitted within the value and is automatically trimmed, but as
standard Perl parsing rules, no space is permitted between the attribute's
name and the open parenthesis of its value:

   :attr( value here )     # is permitted
   :attr (value here)      # not permitted

The following class attributes are supported:

=head3 :isa

   :isa(CLASS)

   :isa(CLASS CLASSVER)

I<Since version 0.57.>

Declares a superclass that this class extends. At most one superclass is
supported.

If the package providing the superclass does not exist, an attempt is made to
load it by code equivalent to

   require CLASS;

and thus it must either already exist, or be locatable via the usual C<@INC>
mechanisms.

The superclass may or may not itself be implemented by C<Object::Pad>, but if
it is not then see L<SUBCLASSING CLASSIC PERL CLASSES> for further detail on
the semantics of how this operates.

An optional version check can also be supplied; it performs the equivalent of

   BaseClass->VERSION( $ver )

=head3 :does

   :does(ROLE)

   :does(ROLE ROLEVER)

I<Since version 0.57.>

Composes a role into the class; optionally requiring a version check on the
role package.

Multiple roles can be composed by using multiple C<:does> attributes, one per
role.

The package will be loaded in a similar way to how the L</:isa> attribute is
handled.

=head3 :repr(TYPE)

Sets the representation type for instances of this class. Must be one of the
following values:

   :repr(native)

The native representation. This is an opaque representation type whose
contents are not specified. It only works for classes whose entire inheritance
hierarchy is built only from classes based on C<Object::Pad>.

   :repr(HASH)

The representation will be a blessed hash reference. The instance data will
be stored in an array referenced by a key called C<Object::Pad/slots>, which
is fairly unlikely to clash with existing storage on the instance. No other
keys will be used; they are available for implementions and subclasses to use.
The exact format of the value stored here is not specified and may change
between module versions, though it can be relied on to be well-behaved as some
kind of perl data structure for purposes of modules like L<Data::Dumper> or
serialisation into things like C<YAML> or C<JSON>.

   :repr(keys)

I<Since version 0.803.>

The representation will be a blessed hash reference. The instance data will
be stored in individual keys of the hash, named after the class and the field
variable name, separated by a C</> symbol. Objects in this representation
should behave predictably with data printing modules like L<Data::Dumper> or
serialisation via C<YAML> or C<JSON>.

These two hash-based representation types may be useful when converting
existing classes into using C<Object::Pad> where there may be existing
subclasses of it that presume a blessed hash for their own use.

   :repr(magic)

The representation will use MAGIC to apply the instance data in a way that is
invisible at the Perl level, and shouldn't get in the way of other things the
instance is doing even in XS modules.

This representation type is the only one that will work for subclassing
existing classes that do not use blessed hashes.

   :repr(pvobj)

I<Since version 0.804.>

The representation will be the C<SVt_PVOBJ> type newly added to Perl, which
offers more efficient storage for object instances. This is only available on
Perl version 5.38.0 onwards.

This is also newly-added and may not be fully tested and reliable yet. Once it
has more real-world testing and has proven reliable it may become the default
instance representation on versions of Perl where it is available.

   :repr(autoselect), :repr(default)

I<Since version 0.23.>

This representation will select one of the representations above depending on
what is best for the situation. Classes not derived from a non-C<Object::Pad>
base class will pick C<native>, and classes derived from non-C<Object::Pad>
bases will pick either the C<HASH> or C<magic> forms depending on whether the
instance is a blessed hash reference or some other kind.

This achieves the best combination of DWIM while still allowing the common
forms of hash reference to be inspected by C<Data::Dumper>, etc. This is the
default representation type, and does not have to be specifically requested.

=head3 :strict(params)

I<Since version 0.43.>

Can only be applied to classes that contain no C<BUILD> blocks. If set, then
the constructor will complain about any unrecognised named arguments passed to
it (i.e. names that do not correspond to the C<:param> of any defined field
and left unconsumed by any C<ADJUST> block).

Since C<BUILD> blocks can inspect the arguments arbitrarily, the presence of
any such block means the constructor cannot determine which named arguments
are not recognised.

This attribute is a temporary stepping-stone for compatibility with existing
code. It is recommended to enable this whenever possible, as a later version
of this module will likely perform this behaviour unconditionally whenever no
C<BUILD> blocks are present.

=head2 class (anon)

   my $class = class :ATTRS... { ... };

I<Since version 0.809.>

If a C<class> keyword is not followed by a package name, it creates an
anonymous class expression. This is an expression that yields a value suitable
to use as a constructor invocant for creating instances of that class, without
specifying what its package name will actually be.

This is useful for creating small one-off instances inline in expressions,
such as in unit tests. Since it still accepts the usual attributes and inner
body statements, it can be useful for creating one-off instances of roles,
with required methods being applied.

   my $testobj = (class {
      apply Role::Under::Test;
      method required { return "a useful value"; }
   })->new;

Due to limitations on how classes work in Perl, anonymous classes are still
backed by long-lived named classes in the global symbol table, unlike true
anonymous functions which can go out of scope and be reclaimed once no
references to them remain in existence. This means that anonymous classes will
retain references to any variables captured within them, even if the class
expression itself goes out of scope and any instances created by it no longer
remain.

=head2 role

   role Name :ATTRS... {
      ...
   }

   role Name :ATTRS...;

I<Since version 0.32.>

Similar to C<class>, but provides a package that defines a new role. A role
acts similar to a class in some respects, and differently in others.

Like a class, a role can have a version, and named methods.

   role Name VERSION {
      method a { ... }
      method b { ... }
   }

A role does not provide a constructor, and instances cannot directly be
constructed. A role cannot extend a class.

A role can declare that it requires methods of given names from any class that
implements the role.

   role Name {
      requires METHOD;
   }

A role can provide instance fields. These are visible to any C<ADJUST> blocks
or methods provided by that role.

I<Since version 0.33.>

   role Name {
      field $f;

      ADJUST { $f = "a value"; }

      method f { return $f; }
   }

I<Since version 0.57> a role can declare that it provides another role:

   role Name :does(OTHERROLE) { ... }
   role Name :does(OTHERROLE OTHERVER) { ... }

This will include all of the methods from the included role. Effectively this
means that applying the "outer" role to a class will imply applying the other
role as well.

The following role attributes are supported:

=head3 :compat(invokable)

I<Since version 0.35.>

Enables a form of backward-compatibility behaviour useful for gradually
upgrading existing code from classical Perl inheritance or mixins into using
roles.

Normally, methods of a role cannot be directly invoked and the role must be
applied to an L<Object::Pad>-based class in order to be used. This however
presents a problem when gradually upgrading existing code that already uses
techniques like roles, multiple inheritance or mixins when that code may be
split across multiple distributions, or for some other reason cannot be
upgraded all at once. Methods within a role that has the C<:compat(invokable)>
attribute applied to it may be directly invoked on any object instance. This
allows the creation of a role that can still provide code for existing classes
written in classical Perl that has not yet been rewritten to use
C<Object::Pad>.

The tradeoff is that a C<:compat(invokable)> role may not create field data
using the L</field> keyword. Whatever behaviours the role wishes to perform
must be provided only by calling other methods on C<$self>, or perhaps by
making assumptions about the representation type of instances.

It should be stressed again: This option is I<only> intended for gradual
upgrade of existing classical Perl code into using C<Object::Pad>. When all
existing code is using C<Object::Pad> then this attribute can be removed from
the role.

=head2 inherit

   inherit Classname;
   inherit Classname VER;

   inherit Classname LIST...;
   inherit Classname VER LIST...;

Declares a superclass that this class extends. At most one superclass is
supported. If present, this declaration must come before any methods or fields
are declared, or any roles applied. (Other compile-time declarations such as
C<use> statements that import utility functions or other behaviours may be
permitted before this, however, provided that they do not interact with the
class structure in any way).

This is a newer form of the C<:isa> attribute intended to be more flexible if
import arguments or other features are added at a later time.

If the package providing the superclass does not exist, an attempt is made to
load it by code equivalent to

   require Classname;

and thus it must either already exist, or be locatable via the usual C<@INC>
mechanisms.

An optional version check can also be supplied; it performs the equivalent of

   Classname->VERSION( $ver )

Experimentally I<since version 0.807>, an optional list of arguments can also
be provided, in similar syntax to those in a C<use> statement. Currently this
list of arguments must be names of fields to be inherited. Only fields in the
base class that are annotated with the C<:inheritable> attribute may be
inherited. Once a field is inherited, methods and other expressions in the
class body can use that field identically to any fields defined by that class
itself.

   class Class1 {
      field $x :inheritable = 123;
   }

   class Class2 {
      inherit Class1 '$x';
      field $y = 456;
      method describe { say "Class2(x=$x,y=$y)" }
   }

   Class2->new->describe;

=head2 apply

   apply Rolename;

   apply Rolename VER;

I<Since version 0.807.>

Composes a role into the class; optionally requiring a version check on the
role package. This is a newer form of the C<:does> attribute intended to be
more flexible if import arguments or other features are added at a later time.

Multiple roles can be composed by using multiple C<:does> attributes, one per
role.

C<apply> statements can be freely mixed with other statements inside the body
of the class. In particular, an C<apply> statement that adds fields or methods
may appear before or after the class has defined some of its own. It is not
required that they appear first.

=head2 field

   field $var;
   field @var;
   field %var;

   field $var :ATTR ATTR...;

   field $var = EXPR;

   field $var //= EXPR;
   field $var ||= EXPR;

   field $var { BLOCK }

I<Since version 0.66.>

Declares that the instances of the class or role have a member field of the
given name. This member field will be accessible as a lexical variable within
any C<method> declarations and C<ADJUST> blocks in the class.

Array and hash members are permitted and behave as expected; you do not need
to store references to anonymous arrays or hashes.

Member fields are private to a class or role. They are not visible to users of
the class, nor inherited by subclasses nor any class that a role is applied
to. In order to provide access to them a class may wish to use L</method> to
create an accessor, or use the attributes such as L</:reader> to get one
generated.

The following field attributes are supported:

=head3 :reader, :reader(NAME)

I<Since version 0.27.>

Generates a reader method to return the current value of the field. If no name
is given, the name of the field is used. A single prefix character C<_> will
be removed if present.

   field $x :reader;

   # equivalent to
   field $x;  method x { return $x }

I<Since version 0.55> these are permitted on any field type, but prior
versions only allowed them on scalar fields. The reader method behaves
identically to how a lexical variable would behave in the same context; namely
returning a list of values from an array or key/value pairs from a hash when
in list context, or the number of items or keys when in scalar context.

   field @items :reader;

   foreach my $item ( $obj->items ) { ... }   # iterates the list of items

   my $count = $obj->items;                   # yields count of items

=head3 :writer, :writer(NAME)

I<Since version 0.27.>

Generates a writer method to set a new value of the field from its arguments.
If no name is given, the name of the field is used prefixed by C<set_>. A
single prefix character C<_> will be removed if present.

   field $x :writer;

   # equivalent to
   field $x;  method set_x { $x = shift; return $self }

I<Since version 0.28> a generated writer method will return the object
invocant itself, allowing a chaining style.

   $obj->set_x("x")
      ->set_y("y")
      ->set_z("z");

I<Since version 0.55> these are permitted on any field type, but prior
versions only allowed them on scalar fields. On arrays or hashes, the writer
method takes a list of values to be assigned into the field, completely
replacing any values previously there.

=head3 :mutator, :mutator(NAME)

I<Since version 0.27.>

Generates an lvalue mutator method to return or set the value of the field.
These are only permitted for scalar fields. If no name is given, the name of
the field is used. A single prefix character C<_> will be removed if present.

   field $x :mutator;

   # equivalent to
   field $x;  method x :lvalue { $x }

I<Since version 0.28> all of these generated accessor methods will include
argument checking similar to that used by subroutine signatures, to ensure the
correct number of arguments are passed - usually zero, but exactly one in the
case of a C<:writer> method.

=head3 :accessor, :accessor(NAME)

I<Since version 0.53.>

Generates a combined reader-writer accessor method to set or return the value
of the field. These are only permitted for scalar fields. If no name is given,
the name of the field is used. A prefix character C<_> will be removed if
present.

This method takes either zero or one additional arguments. If an argument is
passed, the value of the field is set from this argument (even if it is
C<undef>). If no argument is passed (i.e. C<scalar @_> is false) then the
field is not modified. In either case, the value of the field is then
returned.

   field $x :accessor;

   # equivalent to
   field $x;

   method x {
      $x = shift if @_;
      return $x;
   }

=head3 :weak

I<Since version 0.44.>

Generated code which sets the value of this field will weaken it if it
contains a reference. This applies to within the constructor if C<:param> is
given, and to a C<:writer> accessor method. Note that this I<only> applies to
automatically generated code; not normal code written in regular method
bodies. If you assign into the field variable you must remember to call
C<Scalar::Util::weaken> (or C<builtin::weaken> on Perl 5.36 or above)
yourself.

=head3 :param, :param(NAME)

I<Since version 0.41.>

Sets this field to be initialised automatically in the generated constructor.
This is only permitted on scalar fields. If no name is given, the name of the
field is used. A single prefix character C<_> will be removed if present.

Any field that has C<:param> but does not have a default initialisation
expression or block becomes a required argument to the constructor. Attempting
to invoke the constructor without a named argument for this will throw an
exception. In order to make a parameter optional, make sure to give it a
default expression - even if that expression is C<undef>:

   field $x :param;          # this is required
   field $z :param = undef;  # this is optional

Any field that has a C<:param> and an initialisation block will only run the
code in the block if required by the constructor. If a named parameter is
passed to the constructor for this field, then its code block will not be
executed.

Values for fields are assigned by the constructor before any C<BUILD> blocks
are invoked.

=head3 :inheritable

Experimentally I<since version 0.807> fields may be optionally inherited when
deriving a subclass from another. Not every field is allowed to be inherited.
This attribute marks a field as being available for subclasses to inherit.

=head3 Field Initialiser Expressions

I<Since version 0.54> a deferred statement block is also permitted, on any
field variable type. This permits code to be executed as part of the instance
constructor, rather than running just once when the class is set up. Code in a
field initialisation block is roughly equivalent to being placed in a C<BUILD>
or C<ADJUST> block.

I<Since version 0.73> this may also be written as a plain expression
introduced by an equals symbol (C<=>). This is equivalent to using a block.
Note carefully: the equals symbol is part of the C<field> syntax; it is I<not>
simply a runtime assignment operator that happens once at the time the class
is declared. Just like the block form describe above, the expression is
evaluated during the constructor of every instance.

I<Since version 0.74> this expression may also be written using a defined-or
or logical-or assignment operator (C<//=> or C<||=>). In these case, the
default expression will be evaluated and assigned if the caller did not pass a
value to the constructor at all, or if the value passed was undef (for C<//=>)
or false (for C<||=>). For most scalar parameters, where C<undef> is not a
valid value, you probably wanted to use C<//=> to assign defaults.

   class Action {
      field $timeout :param //= 20;
      ...
   }

   # The default of 20 will apply here too
   my $act = Action->new( timeout => $opts{timeout} );

Note that C<$self> is specifically I<not> visible during an initialiser
expression. This is because the object is not yet fully constructed, so it
would be dangerous to allow access to it while in this state. However, the
C<__CLASS__> keyword is available, so initialiser expressions can make use of
class-based dispatch to invoke class-level methods to help provide values.

Field initialier expressions were originally experimental, but I<since version
0.800> no longer emit experimental warnings.

I<Since version 0.806> fields already declared in a class are visible during
the initialisation expression of later fields, and their assigned value can be
used here. If the earlier field had a C<:param> declaration, it will have been
assigned from the value passed to the constructor. Note however that all
C<ADJUST> blocks happen I<after> field initialisation expressions, so any
modified values set in such blocks will not be visible at this time.

Control flow that attempts to leave a field initialiser expression or block is
not permitted. This includes any C<return> expression, any C<next/last/redo>
outside of a loop, with a dynamically-calculated label expression, or with a
label that it doesn't appear in. C<goto> statements are also currently
forbidden, though known-safe ones may be permitted in future.

Loop control expressions that are known at compiletime to affect a loop that
they appear within are permitted.

   field $x { foreach(@list) { next; } }       # this is fine

   field $x { LOOP: while(1) { last LOOP; } }  # this is fine too

=head2 has

I<Since version 0.813> this keyword is no longer recognised.

It used to be an earlier version of what is now the L</field> keyword.

   has $var;
   has @var;
   has %var;

   has $var = EXPR;

   has $var { BLOCK }

Because of the one-shot immediate nature of these initialisation expressions
(and a bunch of other reasons), the keyword was removed.

If you need to evaluate an expression exactly once during the class
declaration and assign its now-constant value to every instace, store it in a
regular C<my> variable instead:

   my $default_var = EXPR;
   field $var = $default_var;

=head2 method

   method NAME {
      ...
   }

   method NAME (SIGNATURE) {
      ...
   }

   method NAME :ATTRS... {
      ...
   }

   method NAME;

Declares a new named method. This behaves similarly to the C<sub> keyword,
except that within the body of the method all of the member fields are also
accessible. In addition, the method body will have a lexical called C<$self>
which contains the invocant object directly; it will already have been shifted
from the C<@_> array.

If the method has no body and is given simply as a name, this declares a
I<required> method for a role. Such a method must be provided by any class
that implements the role. It will be a compiletime error to combine the role
with a class that does not provide this.

The C<signatures> feature is automatically enabled for method declarations. In
this case the signature does not have to account for the invocant instance; 
that is handled directly.

   method m ($one, $two) {
      say "$self invokes method on one=$one two=$two";
   }

   ...
   $obj->m(1, 2);

A list of attributes may be supplied as for C<sub>. The most useful of these
is C<:lvalue>, allowing easy creation of read-write accessors for fields (but
see also the C<:reader>, C<:writer> and C<:mutator> field attributes).

   class Counter {
      field $count;

      method count :lvalue { $count }
   }

   my $c = Counter->new;
   $c->count++;

Every method automatically gets the C<:method> attribute applied, which
suppresses warnings about ambiguous calls resolved to core functions if the
name of a method matches a core function.

The following additional attributes are recognised by C<Object::Pad> directly:

=head3 :override

I<Since version 0.29.>

Marks that this method expects to override another of the same name from a
superclass. It is an error at compiletime if the superclass does not provide
such a method.

=head3 :common

I<Since version 0.62.>

Marks that this method is a class-common method, instead of a regular instance
method. A class-common method may be invoked on class names instead of
instances. Within the method body there is a lexical C<$class> available,
rather than C<$self>. Because it is not associated with a particular object
instance, a class-common method cannot see instance fields.

=head2 method (lexical)

   method $var { ... }

   method $var :ATTRS... (SIGNATURE) { ... }

I<Since version 0.59.>

Declares a new lexical method. Lexical methods are not visible via the package
namespace, but instead are stored directly in a lexical variable (with the
same scoping rules as regular C<my> variables). These can be invoked by
subsequent method code in the same block by using C<< $self->$var(...) >>
method call syntax.

   class WithPrivate {
      field $var;

      # Lexical methods can still see instance fields as normal
      method $inc_var { $var++; say "Var was incremented"; }
      method $dec_var { $var--; say "Var was decremented"; }

      method bump {
         $self->$inc_var;
         say "In the middle";
         $self->$dec_var;
      }
   }

   my $obj = WithPrivate->new;

   $obj->bump;

   # Neither $inc_var nor $dec_var are visible here

This effectively provides the ability to define B<private> methods, as they
are inaccessible from outside the block that defines the class. In addition,
there is no chance of a name collision because lexical variables in different
scopes are independent, even if they share the same name. This is particularly
useful in roles, to create internal helper methods without letting those
methods be visible to callers, or risking their names colliding with other
named methods defined on the consuming class.

=head2 my method

   my method NAME { ... }

I<Since version 0.814> lexical method declarations are supported using the
C<my> keyword prefix. These become available as lexical functions, rather than
being stored in the class package. As a result, they are not available by
named method resolution, package C<< ->can >> lookup, or via the MOP. These
are a convenient alternative to the syntax given above, where the method is
stored anonymously via a lexical variable.

Since lexical methods are not visible to named method resolution, they must be
invoked by function-call syntax, remembering to pass in the invocant as the
first argument:

   my method inner { ... }

   method outer {
      inner($self, @args);
   }

=head2 BUILD

   BUILD {
      ...
   }

   BUILD (SIGNATURE) {
      ...
   }

I<Since version 0.27.>

Declares the builder block for this component class. A builder block may use
subroutine signature syntax, as for methods, to assist in unpacking its
arguments. A build block is not a subroutine and thus is not permitted to use
subroutine attributes (for example C<:lvalue>).

Note that a C<BUILD> block is a named phaser block and not a method. Attempts
to create a method named C<BUILD> (i.e. with syntax C<method BUILD {...}>)
will fail with a compiletime error, to avoid this confusion.

=head2 ADJUST

   ADJUST {
      ...
   }

I<Since version 0.43.>

Declares an adjust block for this component class. This block of code runs
within the constructor, after any C<BUILD> blocks and automatic field value
assignment. It can make any final adjustments to the instance (such as
initialising fields from calculated values).

An adjust block is not a subroutine and thus is not permitted to use
subroutine attributes (except see below). Note that an C<ADJUST> block is a
named phaser block and not a method; it does not use the C<sub> or C<method>
keyword. But, like with C<method>, the member fields are accessible within the
code body, as is the special C<$self> lexical.

Currently, an C<ADJUST> block receives a reference to the hash containing the
current constructor arguments, as per L</ADJUSTPARAMS> (see below). This was
added in version 0.66 but will be removed again as it conflicts with the more
flexible and generally nicer named-parameter C<ADJUST :params> syntax
(see below). Such uses should be considered deprecated. A warning will be
printed to indicate this whenever an C<ADJUST> block uses a signature. This
warning can be quieted by using C<ADJUSTPARAMS> instead. Additionally, a
warning may be printed on code that attempts to access the params hashref via
the C<@_> array.

I<Since version 0.801> in a future version of this module, C<ADJUST> blocks
may be implemented as true blocks and will not permit out-of-block control
flow. At present, they are implemented as one full CV per block, but a warning
is emitted if out-of-block control flow is attempted.

   ADJUST {
      return;
   }

   Using return to leave an ADJUST block is discouraged and will be removed
   in a later version at FILE line LINE.

I<Since version 0.805> an experimental feature can be enabled that puts all
the C<ADJUST> blocks into a single CV, rather than creating one CV for every
block. This is currently being tested for stability, and may become the
default behaviour in a future version. For now it must be requested specially:

   use Object::Pad ':experimental(composed_adjust)';

=head2 ADJUST :params

   ADJUST :params ( :$var1, :$var2, ... ) {
      ...
   }

   ADJUST :params ( :$var1, :$var2, ..., %varN ) {
      ...
   }

I<Since version 0.70; non-experimental since version 0.805.>

An C<ADJUST> block can marked with a C<:params> attribute, meaning that it
consumes additional constructor parameters by assigning them into lexical
variables.

Before the block itself, a list of lexical variables are introduced, inside
parentheses. The name of each one is preceded by a colon, and consumes a
constructor parameter of the same name. These parameters are considered
"consumed" for the purposes of a C<:strict(params)> check.

A named parameter may be provided with default expression, which is evaluated
if no matching named argument is provided to the constructor. As with fields,
if a named parameter has no defaulting expression it becomes a required
argument to the constructor; an exception is thrown by the constructor if it
absent.

For example,

   ADJUST :params ( :$x, :$y = "default", :$z ) { ... }

Note here that C<x> and C<z> are required parameters for the constructor of a
class containing this block, but C<y> is an optional parameter whose value
will be filled in by the expression if not provided. Because these parameters
are named and not positional, there is no ordering constraint; required and
optional parameters can be freely mixed.

Optional parameters can also use the C<//=> and C<||=> operators to provide a
default expression. In these cases, the default will be applied if the caller
did not provide the named argument at all, or if the provided value was not
defined (for C<//=>) or not true (for C<||=>).

   ADJUST :params ( :$name //= "unnamed" ) { ... }

Like with subroutine signature parameters, every declared named parameter is
visible to the defaulting expression of all the later ones. This permits
values to be calculated based on other ones. For example,

   ADJUST :params ( :$thing = undef, :$things = [ $thing ] ) {
      # Here, @$things is a list of values
   }

This permits the caller to pass a list of values via an array reference in
the C<things> parameter, or a single value in C<thing>.

The final element may be a regular hash variable. This requests that all
remaining named parameters are made available inside it. The code in the block
should C<delete> from this hash any parameters it wishes to consume, as with
the earlier case above.

It is I<unspecified> whether named fields or parameters for subclasses yet to
be processed are visible to hashes of earlier superclasses. In the current
implementation they are, but code should not rely on this fact.

Note also that there must be a space between the C<:params> attribute and the
parentheses holding the named parameters. If this space is not present, perl
will parse the parentheses as if they are the value to the C<:params()>
attribute, and this will fail to parse as intended. As with other attributes
and subroutine signatures, this whitespace B<is> significant.

(This notation is borrowed from a plan to add named parameter support to
perl's subroutine signature syntax).

=head2 ADJUSTPARAMS

I<Since version 0.51.>

   ADJUSTPARAMS ( $params ) {    # on perl 5.26 onwards
      ...
   }

   ADJUST {
      my $params = shift;
      ...
   }

A variant of an C<ADJUST> block that receives a reference to the hash
containing the current constructor parameters. This hash will not contain any
constructor parameters already consumed by L</:param> declarations on any
fields, but only the leftovers once those are processed.

The code in the block should C<delete> from this hash any parameters it wishes
to consume. Once all the C<ADJUST> blocks have run, any remaining keys in the
hash will be considered errors, subject to the L</:strict(params)> check.

=head2 __CLASS__

   my $classname = __CLASS__;

I<Since version 0.72.>

Only valid within the body (or signature) of a C<method>, an C<ADJUST> block,
or the initialising expression of a C<field>. Yields the class name of the
instance that the method, block or expression is invoked on.

This is similar to the core perl C<__PACKAGE__> constant, except that it cares
about the dynamic class of the actual instance, not the static class the code
belongs to. When invoked by a subclass instance that inherited code from its
superclass it yields the name of the class of the instance regardless of which
class defined the code.

For example,

   class BaseClass {
      ADJUST { say "Constructing an instance of " . __CLASS__; }
   }

   class DerivedClass :isa(BaseClass) { }

   my $obj = DerivedClass->new;

Will produce the following output

   Constructing an instance of DerivedClass

This is particularly useful in field initialisers for invoking (constant)
methods on the invoking class to provide default values for fields. This way a
subclass could provide a different value.

   class Timer {
      use constant DEFAULT_DURATION => 60;
      field $duration = __CLASS__->DEFAULT_DURATION;
   }

   class ThreeMinuteTimer :isa(Timer) {
      use constant DEFAULT_DURATION => 3 * 60;
   }

=head2 requires

   requires NAME;

Declares that this role requires a method of the given name from any class
that implements it. It is an error at compiletime if the implementing class
does not provide such a method.

This form of declaring a required method is now vaguely discouraged, in favour
of the bodyless C<method> form described above.

=head1 CREPT FEATURES

While not strictly part of being an object system, this module has
nevertheless gained a number of behaviours by feature creep, as they have been
found useful.

=head2 Implied Pragmata

B<The following behaviour is likely to be removed in a later version of this
module.>

In order to encourage users to write clean, modern code, the body of the
C<class> block currently acts as if the following pragmata are in effect:

   use strict;
   use warnings;
   no indirect ':fatal';  # or  no feature 'indirect' on perl 5.32 onwards
   use feature 'signatures';

This behaviour was designed early around the original "line-0" version of the
Perl 7 plan, which has subsequently been found to be a bad design and
abandoned. That leaves this module in an unfortunate situation, because its
behaviour here does not match the plans for core perl; where the
recently-added C<class> keyword does none of this, although the C<method>
keyword always behaves as if signatures were enabled anyway.

It is eventually planned that this behaviour will be removed from
C<Object::Pad> entirely (except for enabling the C<signatures> feature). While
that won't in itself break any existing code, it would mean that code which
previously ran with the protection of C<strict> and C<warnings> would now not
be. A satisfactory solution to this problem has not yet been found, but until
then it is suggested that code using this module remembers to explicitly
enable this set of pragmata before using the C<class> keyword.

A handy way to do this is to use the C<use VERSION> syntax; v5.36 or later
will already perform all of the pragmata listed above.

   use v5.36;

If you import this module with a module version number of C<0.800> or higher
it will enable a warning if you forget to enable C<strict> and C<warnings>
before using the C<class> or C<roll> keywords:

   use Object::Pad 0.800;

   class X { ... }

Z<>

=for highlighter

   class keyword enabled 'use strict' but this will be removed in a later version at FILE line 3.
   class keyword enabled 'use warnings' but this will be removed in a later version at FILE line 3.

=for highlighter language=perl

=head2 Yield True

B<The following behaviour is likely to be removed in a later version of this
module.>

A C<class> statement or block will yield a true boolean value. This means that
it can be used directly inside a F<.pm> file, avoiding the need to explicitly
yield a true value from the end of it.

As with the implied pragmata above, this behaviour has also been found to be a
bad design and will likely be removed soon. For now it is suggested not to
rely on it and instead either use the new C<module_true> feature already part
of the C<use v5.38> pragma, or on older perls simply remember to put an
explicit true value at the end of the file.

=head1 SUBCLASSING CLASSIC PERL CLASSES

There are a number of details specific to the case of deriving an
C<Object::Pad> class from an existing classic Perl class that is not
implemented using C<Object::Pad>.

=head2 Storage of Instance Data

Instances will pick either the C<:repr(HASH)> or C<:repr(magic)> storage type.

=head2 Object State During Methods Invoked By Superclass Constructor

It is common in classic Perl OO style to invoke methods on C<$self> during
the constructor. This is supported here since C<Object::Pad> version 0.19.
Note however that any methods invoked by the superclass constructor may not
see the object in a fully consistent state. (This fact is not specific to
using C<Object::Pad> and would happen in classic Perl OO as well). The field
initialisers will have been invoked but the C<BUILD> and C<ADJUST> blocks will
not.

For example; in the following

   package ClassicPerlBaseClass {
      sub new {
         my $self = bless {}, shift;
         say "Value seen by superconstructor is ", $self->get_value;
         return $self;
      }
      sub get_value { return "A" }
   }

   class DerivedClass :isa(ClassicPerlBaseClass) {
      field $_value = "B";
      ADJUST {
         $_value = "C";
      }
      method get_value { return $_value }
   }

   my $obj = DerivedClass->new;
   say "Value seen by user is ", $obj->get_value;

Until the C<ClassicPerlBaseClass::new> superconstructor has returned the
C<ADJUST> block will not have been invoked. The C<$_value> field will still
exist, but its value will be C<B> during the superconstructor. After the
superconstructor, the C<BUILD> and C<ADJUST> blocks are invoked before the
completed object is returned to the user. The result will therefore be:

=for highlighter

   Value seen by superconstructor is B
   Value seen by user is C

=for highlighter language=perl

=head1 STYLE SUGGESTIONS

While in no way required, the following suggestions of code style should be
noted in order to establish a set of best practices, and encourage consistency
of code which uses this module.

=head2 $VERSION declaration

While it would be nice for CPAN and other toolchain modules to parse the
embedded version declarations in C<class> statements, the current state at
time of writing (June 2020) is that none of them actually do. As such, it will
still be necessary to make a once-per-file C<$VERSION> declaration in syntax
those modules can parse.

Further note that these modules will also not parse the C<class> declaration,
so you will have to duplicate this with a C<package> declaration as well as a
C<class> keyword. This does involve repeating the package name, so is slightly
undesirable.

It is hoped that eventually upstream toolchain modules will be adapted to
accept the C<class> syntax as being sufficient to declare a package and set
its version.

See also

=over 2

=item *

L<https://github.com/Perl-Toolchain-Gang/Module-Metadata/issues/33>

=back

=head2 File Layout

Begin the file with a C<use Object::Pad> line; ideally including a
minimum-required version. This should be followed by the toplevel C<package>
and C<class> declarations for the file. As it is at toplevel there is no need
to use the block notation; it can be a unit class.

There is no need to C<use strict> or apply other usual pragmata; these will
be implied by the C<class> keyword.

   use Object::Pad 0.16;

   package My::Classname 1.23;
   class My::Classname;

   # other use statements

   # field, methods, etc.. can go here

=head2 Field Names

Field names should follow similar rules to regular lexical variables in code -
lowercase, name components separated by underscores. For tiny examples such as
"dumb record" structures this may be sufficient.

   class Tag {
      field $name  :mutator;
      field $value :mutator;
   }

In larger examples with lots of non-trivial method bodies, it can get
confusing to remember where the field variables come from (because we no
longer have the C<< $self->{ ... } >> visual clue). In these cases it is
suggested to prefix the field names with a leading underscore, to make them
more visually distinct.

   class Spudger {
      field $_grapefruit;

      ...

      method mangle {
         $_grapefruit->peel; # The leading underscore reminds us this is a field
      }
   }

=cut

sub VERSION
{
   my $pkg = shift;

   my $ret = $pkg->SUPER::VERSION( @_ );

   if( @_ ) {
      my $ver = version->parse( @_ );

      # Only bother to store it if it's >= v0.800
      $^H{"Object::Pad/imported-version"} = $ver->numify if $ver ge v0.800;
   }

   return $ret;
}

sub import
{
   my $class = shift;
   my $caller = caller;

   $class->import_into( $caller, @_ );
}

sub _import_experimental
{
   shift;
   my ( $syms, @experiments ) = @_;

   my %enabled;

   my $i = 0;
   while( $i < @$syms ) {
      my $sym = $syms->[$i];

      if( $sym eq ":experimental" ) {
         carp "Enabling all Object::Pad experiments with an unqualified :experimental";
         $enabled{$_}++ for @experiments;
      }
      elsif( $sym =~ m/^:experimental\((.*)\)$/ ) {
         foreach my $tag ( split m/\s+/, $1 =~ s/^\s+|\s+$//gr ) {
            if( $tag eq ":all" ) {
               $enabled{$_}++ for @experiments;
            }
            else {
               $enabled{$tag}++;
            }
         }
      }
      else {
         $i++;
         next;
      }

      splice @$syms, $i, 1, ();
   }

   foreach ( @experiments ) {
      $^H{"Object::Pad/experimental($_)"}++ if delete $enabled{$_};
   }

   croak "Unrecognised :experimental features @{[ keys %enabled ]}" if keys %enabled;
}

sub _import_configuration
{
   shift;
   my ( $syms ) = @_;

   # Undocumented options, purely to support Feature::Compat::Class adjusting
   # the behaviour to closer match core's  use feature 'class'

   my $i = 0;
   while( $i < @$syms ) {
      my $sym = $syms->[$i];

      if( $sym =~ m/^:config\((.*)\)$/ ) {
         foreach my $opt ( split m/\s+/, $1 =~ s/^\s+|\s+$//gr ) {
            if( $opt =~ m/^(only_class_attrs|only_field_attrs)=(.*)$/ ) {
               # Store an entire sub-hash inside the hints hash. This won't
               # survive squashing into a COP for runtime but we only need it
               # during compile so that's OK
               my ( $name, $attrs ) = ( $1, $2 );
               $^H{"Object::Pad/configure($name)"} = { map { $_ => 1 } split m/,/, $attrs };
            }
            else {
               $^H{"Object::Pad/configure($opt)"}++
            }
         }
      }
      else {
         $i++;
         next;
      }

      splice @$syms, $i, 1, ();
   }
}

sub import_into
{
   my $class = shift;
   my $caller = shift;

   $class->_import_experimental( \@_, qw( init_expr mop custom_field_attr adjust_params composed_adjust inherit_field ) );

   $class->_import_configuration( \@_ );

   my %syms = map { $_ => 1 } @_;

   # Default imports
   unless( %syms ) {
      $syms{$_}++ for qw( class role inherit apply method field has requires BUILD ADJUST );
   }

   delete $syms{$_} and $^H{"Object::Pad/$_"}++ for qw( class role inherit apply method field has requires BUILD ADJUST );

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

# The universal base-class methods

sub Object::Pad::UNIVERSAL::BUILDARGS
{
   shift; # $class
   return @_;
}

# Back-compat wrapper
sub Object::Pad::MOP::SlotAttr::register
{
   shift; # $class
   croak "Object::Pad::MOP::SlotAttr->register is now removed; use Object::Pad::MOP::FieldAttr->register instead";
}

=head1 WITH OTHER MODULES

=head2 Syntax::Keyword::Dynamically

A cross-module integration test asserts that C<dynamically> works correctly
on object instance fields:

   use Object::Pad;
   use Syntax::Keyword::Dynamically;

   class Container {
      field $value = 1;

      method example {
         dynamically $value = 2;
         ,..
         # value is restored to 1 on return from this method
      }
   }

=head2 Future::AsyncAwait

As of L<Future::AsyncAwait> version 0.38 and L<Object::Pad> version 0.15, both
modules now use L<XS::Parse::Sublike> to parse blocks of code. Because of this
the two modules can operate together and allow class methods to be written as
async subs which await expressions:

   use Future::AsyncAwait;
   use Object::Pad;

   class Example
   {
      async method perform ($block)
      {
         say "$self is performing code";
         await $block->();
         say "code finished";
      }
   }

These three modules combine; there is additionally a cross-module test to
ensure that object instance fields can be C<dynamically> set during a
suspended C<async method>.

=head2 Devel::MAT

When using L<Devel::MAT> to help analyse or debug memory issues with programs
that use C<Object::Pad>, you will likely want to additionally install the
module L<Devel::MAT::Tool::Object::Pad>. This will provide new commands and
extend existing ones to better assist with analysing details related to
C<Object::Pad> classes and instances of them.

=for highlighter

   pmat> fields 0x55d7c173d4b8
   The field AV ARRAY(3)=NativeClass at 0x55d7c173d4b8
   Ix Field   Value
   0  $sfield SCALAR(UV) at 0x55d7c173d938 = 123
   ...

   pmat> identify 0x55d7c17606d8
   REF() at 0x55d7c17606d8 is:
   └─the %hfield field of ARRAY(3)=NativeClass at 0x55d7c173d4b8, which is:
   ...

=for highlighter language=perl

=head1 DESIGN TODOs

The following points are details about the design of pad field-based object
systems in general:

=over 4

=item *

Is multiple inheritance actually required, if role composition is implemented
including giving roles the ability to use private fields?

=item *

Consider the visibility of superclass fields to subclasses. Do subclasses
even need to be able to see their superclass's fields, or are accessor methods
always appropriate?

Concrete example: The C<< $self->{split_at} >> access that
L<Tickit::Widget::HSplit> makes of its parent class
L<Tickit::Widget::LinearSplit>.

=back

=head1 IMPLEMENTATION TODOs

These points are more about this particular module's implementation:

=over 4

=item *

Consider multiple inheritance of subclassing, if that is still considered
useful after adding roles.

=item *

Work out why C<no indirect> doesn't appear to work properly before perl 5.20.

=item *

Work out why we don't get a C<Subroutine new redefined at ...> warning if we

  sub new { ... }

=item *

The C<local> modifier does not work on field variables, because they appear to
be regular lexicals to the parser at that point. A workaround is to use
L<Syntax::Keyword::Dynamically> instead:

   use Syntax::Keyword::Dynamically;

   field $loglevel;

   method quietly {
      dynamically $loglevel = LOG_ERROR;
      ...
   }

=back

=cut

=head1 FEEDBACK

The following resources are useful forms of providing feedback, especially in
the form of reports of what you find good or bad about the module, requests
for new features, questions on best practice, etc...

=over 4

=item *

The RT queue at L<https://rt.cpan.org/Dist/Display.html?Name=Object-Pad>.

=item *

The C<#cor> IRC channel on C<irc.perl.org>.

=back

=cut

=head1 SPONSORS

With thanks to the following sponsors, who have helped me be able to spend
time working on this module and other perl features.

=over 4

=item *

Oetiker+Partner AG L<https://www.oetiker.ch/en/>

=item *

Deriv L<http://deriv.com>

=item *

Perl-Verein Schweiz L<https://www.perl-workshop.ch/>

=back

Additional details may be found at
L<https://github.com/Ovid/Cor/wiki/Sponsors>.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
