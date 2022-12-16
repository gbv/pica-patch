---
title: PICA Patch
language: en
---

**PICA Patch** is a data format to record changes between records in PICA+ format.

* author: Jakob Voß
* version: 0.9.1
* date: 2022-12-16

## Table of Contents

- [Introduction](#introduction)
- [Data Model](#data-model)
- [Serialization](#serialization)
- [Algorithms](#algorithms)
- [Examples](#examples)
- [Application](#application)
- [Changlog](#changelog)

## Introduction

This document defines **PICA Patch**, a data format to express changes to
records in PICA+ format in a machine-readable and reproducible way.  Records in
PICA Patch format specify fields to add, to remove, and/or to compare with an
existing PICA+ record. The rationale of PICA Patch is to communicate changes of
PICA records in an unambigous, descriptive form (as data) instead of imperative
instructions (as code).

The specification consists of a **normative part** with

- definition of a [data model](#data-model) required to understand the format,
- definition of interchangeable [serialization formats](#serialization) to encode and exchange PICA Patch records,
- definition of [algorithms](#algorithms) to apply and create PICA Patch records

and an **informative part** with

- [examples](#examples) of serialization and patching and
- [application](#application) notes.

## Data Model

A **PICA field** consists of:

- a **tag**, being a string that matches regular expression `[012][0-9][0-9][A-Z@]`.
    The first digit is called **level** of the field.
- an optional **occurrence**, being a string of two digits for level `0` and `1`, or two or three digits for level `2`. The occurrence must not consist of zeroes only, but a non-existing occurrence may informally be referred to as "occurrence zero".
- a non-empty sequence of **subfields**, each consting of:
    - a **subfield code**, being an alphanumeric character (one of `0-9`, `A-Z`, `a-z`)
    - a **subfield value**, being a string

Two PICA fields are identical if then have same tag, same occurrence and same subfield sequence with same order of subfield codes and subfield values.

A **PICA record** is a sequence of PICA fields.

A **PICA Patch record** is a sequence of PICA fields, each annotated with an **annotation character**, which is:

- either plus (`+`, byte code `2B`) to add the field,
- or minus (`-`, byte code `2D`) to remove the field,
- or space (byte code `20`) to compare the field as precondition.

## Serialization

PICA Patch records, can be encoded in multiple losslessly convertible forms:

- [PICA Patch Normalized](#pica-patch-plain) is best for human inspection
- [PICA Patch Normalized](#pica-patch-normalized) is easier to process automatically
- [PICA Patch JSON](#pica-patch-json) is useful in web applications

### PICA Patch Plain

In PICA Patch Plain each PICA field is encoded as a sequence of:

1. the annotation character (plus, minus or space)
2. a space (byte code `20`)
3. the tag
4. optionally the occurrence, preceded by `/` (byte code `2F`)
5. a space
6. a non-empty sequence of subfields, each consisting of:
    - the subfield indicator `$` (byte code `24`)
    - the subfield code
    - the subfield value with `$` replaced by `$$` for escaping
7. a newline character (byte code `A0`)

A PICA Patch record is a sequence of encoded PICA fields. Multiple records must be separated by empty lines (non-empty sequences of newline characters).

*Note (non-normative): A PICA Patch record having every field annotated with a space in PICA Patch Plain is serialized identical to [PICA Plain](https://format.gbv.de/pica/plain) serialization of the PICA record without annotations.*

### PICA Patch Normalized

In PICA Patch Normalized each PICA Patch record is encoded as sequence of fields, terminated by a newline character (byte code `A0`). Each field consists of:

1. the tag
2. optionally the occurrence, preceded by `/` (byte code `2F`)
2. the annotation character (plus, minus or space)
4. a non-empty sequence of subfields, each consisting of
    - the subfield indicator (byte code `1F`)
    - the subfield code
    - the subfield value
5. an end-of-field character (byte code `1E`)

*Note (non-normative): A PICA Patch record having every field annotated with a space in PICA Patch Normalized is serialized identical to [PICA Normalized serialization](https://format.gbv.de/pica/normalized) of the PICA record without annotations.*

### PICA Patch JSON

In PICA Patch JSON each PICA Patch record is encoded as JSON array of fields. Each field is encoded as JSON array with the following members, all given as JSON strings:

1. the tag
2. the occurrence or an empty string if the field has no occurrence
3. the subfields as alternating subfield codes and subfield values
4. the annotation character (plus, minus or space)

## Algorithms

Two PICA records *A* and *B* can be compared to calculate their difference as PICA Patch record *P* ([diff algorithm](#diff-algorithm)). In reverse the application of *P* to *A* ([patch algorithm](#patch-algorithm)) will result in *A*. Both algorithms require *A* and *B* or *A* and *P* respectively to met common [requirements](#requirements) to be applicable.

### Requirements

- **Same levels:** 
  Diff and patch are only defined for PICA (patch) records with same same level for all of their fields. Applications may filter out fields with different level or cancel with an error. Records of level 2 must further have same occurrence for all of their fields.

- **Unique fields:**
  A PICA (patch) record must not contain [identical fields](#data-model).

- **Sorted fields:**
  PICA (patch) records must also be sorted by tag first and occurrence second, and annotation third to apply diff or patch algorithm. Annotations are not sorted by theor byte code but space first, minus second and plus third. Applications should automatically sort fields to fulfil this requirement.

### Diff algorithm

The difference between two PICA records *A* and *B* can be calculated as PICA Patch record *P* as following, based on the definition of [identical fields](#data-model):

1. Find all fields given in *A* but not given in *B*. Let *P* be these fields annotated with `-`.
2. Find all fields given in *B* but not given in *C*. Add these fields annotated with `+` to *P*.
4. Sort fields of *P* as defined by the [requirements](#requirements).

### Patch algorithm

A PICA record *R* is modified with a PICA Patch record *P* by the following algorithm:

**Precondition**

- Get all fields of *P* annotated with space or minus. If any of
  this fields does not exist with same field content in *R* cancel with a warning.

**Removals**

- Remove all fields of *P* annotated with -from *R*

**Additions**

- For each field of *P* annotated with +: add the field to *R*
  unless it already exists with same field content in *R*.

**Maintain sorting** of *R*


*Note: Patch is an idempotent operation. Patching a record multiple times with the same PICA patch record does not change the result if the PICA Patch record contains no fields annotated with ?????i*

## Examples

This section is non-normative.

### Serializations

The following PICA Patch record in Plain syntax consists of three fields, annotated by space, `-` and `+` respectively:

~~~
  003@ $01234
- 021A $aA book
+ 021A $aA book$hfor reading
~~~

Normalized syntax is binary so it can only be shown in modified form: Special byte codes are represented in brackets and line breaks have been added for readability:

~~~
003@ \[1F\]01234\[1E\]\
021A-\[1F\]aA book\[1E\]\
021A+\[1F\]aA book\[1F\]hfor reading\[1E\]\[A0\]
~~~

The same record in JSON syntax is:

~~~json
[
  ["003@","","0","1234"," "],
  ["021A","","a","A book","-"],
  ["021A","","a","A book","h","for reading","+"]
 ]
~~~

While Plain is recommended to communicate and inspect data, Normalized and JSON syntax are recommended for further processing. The following Perl script can be used to convert from PICA Patch Plain to PICA Patch Normalized:

~~~perl
#!/usr/bin/perl
use v5.14.1;
while (<>) {
  say && next if $_ eq ''; # end of record
  die "invalid PICA Patch Plain at line $.: '$_'\n"
  if $_ !~ qr{^([ +-]) ([012]\d\d[A-Z@](/\d+)?) \$(.+)};
  my $value = join '$', map { s/\$/\x1F/gr; } split '\$\$', $4;
  print "$2$1\x1F$value\x1E";
}
~~~

### Patch

Unconditionally add field 021Awith one subfield \$aand value A book to a
record, unless the record already has field021Awith exactely this value:

~~~
+ 021A $aA book
~~~

Same as above but cancel with an error if the record to be patched does
not have field `003@` with only subfield `0`having value 1234:

~~~
  003@ $01234
+ 021A $aA book
~~~

Replace content field 021Aor give a warning if current content is not as
expected:

~~~
- 021A $aA book
+ 021A $aA book$hfor reading
~~~

## Application

PICA+ is used primarily in CBS databases and PICA Patch was inspired by
record versioning in CBS. When applied with CBS databases, the
application should inspect PICA Patch records and run additional processing
such:

-   Use field `003@` to look up which record to modfiy (when annotated by )
    or to delete (when annotated by -)
-   Disallow modification of special fields and field values.
-   Ignore subfields created by expansion (`$8` for online-expansion and other subfields for offline-expansion)
-   Extend modification to automatically modify special fields such as date of modification (`001B`)
-   Validate resulting record against Avram Schema.

Which and how to do this processing is out of the scope of this specification.

## Changes

This document is managed in a git repository at <https://github.com/gbv/pica-patch>.
