---
title: PICA Patch
language: en
---

**PICA Patch** is a data format to express changes between records in PICA+ format.

* author: Jakob Voß
* date: 2023-08-29

## Table of Contents

- [Introduction](#introduction)
- [Data Model](#data-model)
- [Serialization](#serialization)
  - [PICA Patch Plain](#pica-patch-plain)
  - [PICA Patch JSON](#pica-patch-json)
  - [PICA Patch Normalized](#pica-patch-normalized)
- [Algorithms](#algorithms)
  - [Diff algorithm](#diff-algorithm)
  - [Patch algorithm](#patch-algorithm)
- [Patch examples](#patch-examples)
- [Application notes](#application-notes)
- [Changlog](#changelog)

## Introduction

This document defines **PICA Patch**, a data format to express changes and
differences between PICA+ records in a machine-readable and reproducible way.
Records in PICA Patch format specify fields to add, to remove, and/or to
compare with an existing PICA record. The rationale of PICA Patch is to
communicate changes of PICA+ records in unambigous, descriptive form (as
data) instead of imperative instructions (as code).

The specification consists of a **normative part** with

- definition of a [data model](#data-model) of PICA+ records and PICA Patch records,
- definition of interchangeable [serialization formats](#serialization) to encode and exchange PICA Patch records,
- definition of [algorithms](#algorithms) to apply and create PICA Patch records

and an **informative part** with notes, examples and a [changelog](#changelog).

## Data Model

A **PICA field** consists of:

- a **tag**, being a string that matches regular expression `[012][0-9][0-9][A-Z@]`.
    The first digit is called **level** of the field.
- an optional **occurrence**, being a string of two digits for level `0` and `1`, or two or three digits for level `2`. At least one digit must be other than `0`.
- a non-empty sequence of **subfields**, each consting of:
    - a **subfield code**, being an alphanumeric character (one of `0-9`, `A-Z`, `a-z`)
    - a **subfield value**, being a (possibly empty) string

Two PICA fields are identical if they have same tag, same occurrence and same subfield sequence (same codes and values in same order).

A **PICA record** is a sequence of PICA fields.

A **PICA Patch record** is a sequence of PICA fields, each annotated with an **annotation character**, which is:

- either plus (`+`, byte code `2B`) to add the field,
- or minus (`-`, byte code `2D`) to remove the field,
- or space (byte code `20`) to compare the field as precondition.

## Serialization

PICA Patch records, can be encoded in multiple losslessly convertible forms:

- [PICA Patch Plain](#pica-patch-plain) is best for human inspection
- [PICA Patch JSON](#pica-patch-json) is useful in web applications
- [PICA Patch Normalized](#pica-patch-normalized) can be easier to process automatically

### PICA Patch Plain

In PICA Patch Plain each PICA field is encoded as a sequence of:

1. either the annotation character (plus, minus or space) followed by a space (byte code `20`), or a possibly empty sequence of spaces as alias for annotation character space
2. the tag
3. the optional occurrence preceded by `/` (byte code `2F`)
4. a space
5. a non-empty sequence of subfields, each consisting of:
    - the subfield indicator `$` (byte code `24`)
    - the subfield code
    - the subfield value with `$` replaced by `$$` for escaping
6. a newline character (byte code `A0`)

A PICA Patch record is a sequence of encoded PICA fields. Multiple records must be separated by empty lines (non-empty sequences of newline characters).

*Example: A PICA Patch record in Plain consisting of three fields, annotated by space, minus and plus respectively:*

~~~pica-patch
  003@ $01234
- 021A $aA book
+ 021A $aA book$hfor reading
~~~

*Note: A PICA Patch record having every field annotated with a space in PICA Patch Plain is serialized identical to [PICA Plain](https://format.gbv.de/pica/plain) serialization of the PICA record without annotations.*

### PICA Patch JSON

In PICA Patch JSON each PICA Patch record is encoded as JSON array of fields. Each field is encoded as JSON array with the following members, all given as JSON strings:

1. the tag
2. the occurrence or an empty string if the field has no occurrence
3. the subfields as alternating subfield codes and subfield values
4. the annotation character (plus, minus or space)

*Example: The same PICA Patch record as given above, in PICA Patch JSON:*

~~~json
[
  ["003@","","0","1234"," "],
  ["021A","","a","A book","-"],
  ["021A","","a","A book","h","for reading","+"]
 ]
~~~

*Note: PICA Patch JSON is an extension of [PICA JSON](https://format.gbv.de/pica/json) by an additional array element in each field. Both formats can be distinguished by checking whether the number of array elements in a field is odd or even.*

### PICA Patch Normalized

In PICA Patch Normalized each PICA Patch record is encoded as sequence of fields, terminated by a newline character (byte code `A0`). Each field consists of:

1. the tag
2. the optional occurrence preceded by `/` (byte code `2F`)
2. the annotation character (plus, minus or space)
4. a non-empty sequence of subfields, each consisting of
    - the subfield indicator (byte code `1F`)
    - the subfield code
    - the subfield value
5. an end-of-field character (byte code `1E`)

*Example: The same PICA Patch record as given above, in PICA Patch Normalized. For readability special byte codes are shown in brackets and line breaks have been added:*

~~~txt
003@ [1F]01234[1E]
021A-[1F]aA book[1E]
021A+[1F]aA book[1F]hfor reading[1E][A0]
~~~

*Note: A PICA Patch record having every field annotated with a space in PICA Patch Normalized is serialized identical to [PICA Normalized](https://format.gbv.de/pica/normalized) serialization of PICA records without annotations.*

## Algorithms

Two PICA records *A* and *B* can be compared to calculate their difference as PICA Patch record *P* ([diff algorithm](#diff-algorithm)). In reverse the application of *P* to *A* will result in *A* ([patch algorithm](#patch-algorithm)). Both algorithms require *A* and *B* or *A* and *P* respectively to meet the following requirements to be applicable:

- **Same levels:** 
  Diff and patch are only defined for PICA (patch) records with same same level for all of their fields. Records of level 2 must further have same occurrence for all of their fields. Applications may filter out fields with different level or reject application with an error.

- **Unique fields:**
  A PICA (patch) record must not contain [identical fields](#data-model).
  Applications may ignore this requirement by automatically removing duplicated fields.

### Diff algorithm

The difference between two PICA records *A* and *B* can be calculated as PICA Patch record *P* as following, based on the definition of [identical fields](#data-model):

1. Find all fields given in *A* but not given in *B*. Let *P* be these fields annotated with minus.
2. Find all fields given in *B* but not given in *C*. Add these fields annotated with plus to *P*.

### Patch algorithm

A PICA record *R* is modified ("patched") with a PICA Patch record *P* based on the following algorithm or an equivalent implementation:

1. **Precondition**: Get all fields of *P* annotated with space or minus. If any of
    this fields does not exist with same field content in *R* reject patch.

2. **Removals**: Remove all fields of *P* annotated with minus from *R*

3. **Additions**: For each field of *P* annotated with plus: add the field to *R*
    unless an identical fields already exists in *R*.

Patching is an idempotent operation: that means patching a record multiple times with the same PICA Patch record does not change the result.

## Patch Examples

Unconditionally add field `021A` with one subfield `$a` and value `A book` to a
record, unless the record already has field `021A` with exactely this value:

~~~pica-patch
+ 021A $aA book
~~~

Same as above but reject patch with an error if the record to be patched does
not have field `003@` with only subfield `0`having value `1234`:

~~~pica-patch
  003@ $01234
+ 021A $aA book
~~~

Replace content field `021A` or reject patch if current content is not as
expected:

~~~pica-patch
- 021A $aA book
+ 021A $aA book$hfor reading
~~~

Extend record having field `045R` with given subfields (link to RVK notation `TY 1200` in K10plus) with a field `045Q/01` (corresponding BK notation `38.27` based on a mapping):

~~~pica-patch
+ 045Q/01 $9106407171$Acoli-conc RVK-BK$Ahttps://coli-conc.gbv.de/api/mappings/0f12d635-212f-4933-ae3a-ea36c1a92e66
  045R $91271953439
~~~

## Application notes

PICA+ is used primarily in CBS databases and PICA Patch was inspired by record
versioning in CBS. When applied with CBS databases, the application should
inspect and modify PICA Patch records depending on use case, for instance:

- Use field `003@` or another identifier field to look up which record to modfiy
  (when annotated by space) or to delete (when annotated by minus)
- Disallow modification of special fields and field values
- Ignore subfields created by expansion of subfield `$9`
  (`$8` for online-expansion and other subfields for offline-expansion)
- Extend modification to automatically modify special fields such as date of modification  (`001B`)
- Validate records against an [Avram Schema](https://format.gbv.de/schema/avram/specification)

Which and how to do this processing is out of the scope of this specification.

## Changelog

This document is managed in a git repository at <https://github.com/gbv/pica-patch>.

* 2023-08-29: Allow any sequence of spaces for annotation character space in PICA Patch Plain. Remove sorting requirement.
* 2023-01-23: Typos, layout and clarify idempotency of patching.
* 2022-12-20: Published revised version at <https://format.gbv.de/pica/patch/specification>
* 2022-09-14: First English version, shared after CBS partner meeting

